defmodule OpenphoneRecorder.ConversationSummarizer do
  require Logger

  alias OpenphoneRecorder.ConversationSummarizers
  alias OpenphoneRecorder.ConversationSummarizers.ConversationSummarizer
  alias OpenphoneRecorder.Summarizers.Summarizer
  alias OpenphoneRecorder.Statements
  alias OpenphoneRecorder.Statements.Statement
  alias OpenphoneRecorder.Chunker
  alias OpenphoneRecorder.Summaries
  alias OpenphoneRecorder.Summaries.Summary
  alias OpenphoneRecorder.StatementSummaries
  alias OpenphoneRecorder.Conversations.Conversation
  alias OpenphoneRecorder.Tokens
  alias OpenphoneRecorder.DateSupport
  alias PgRanges.TsRange

  def create_daily_summaries(
        %ConversationSummarizer{
          id: conversation_summarizer_id,
          conversation: %Conversation{} = conversation,
          summarizer: %Summarizer{} = summarizer
        },
        opts \\ []
      ) do
    Statements.list_statements(
      filters: [
        conversation_id: conversation.id,
        not_summarizer_id: summarizer.id,
        before: DateSupport.start_of_today(opts)
      ],
      preloads: [
        participant: [phone_number: :contact]
      ],
      order_by: [occurred_at: :desc]
    )
    |> Chunker.apply(chunkers: [:daily])
    |> Enum.map(fn statements ->
      first_statement = Enum.at(statements, 0)
      last_statement = Enum.at(statements, -1)

      IO.inspect(4096 - Chunker.prompt_count(:daily, []))

      text =
        statements
        |> Chunker.apply(
          chunkers: [:token_count],
          max_tokens: Tokens.max_text_output_count(chunker: :daily)
        )
        |> case do
          [statements] ->
            context = join_content(statements)
            prompt = Chunker.prompt(:daily, context, opts)

            {:ok, text} =
              create_completion(
                model: "text-davinci-003",
                prompt: prompt,
                max_tokens: Tokens.max_text_output_count(opts),
                temperature: 0
              )

            text

          chunked_statements ->
            context =
              Enum.map(chunked_statements, fn statements ->
                context = join_content(statements)
                prompt = Chunker.prompt(:token_count, context, opts)

                {:ok, text} =
                  create_completion(
                    model: "text-davinci-003",
                    prompt: prompt,
                    max_tokens: Tokens.max_text_output_count(opts),
                    temperature: 0
                  )

                text
              end)
              |> Enum.join("\n")

            prompt = Chunker.prompt(:daily, context, opts)

            {:ok, text} =
              create_completion(
                model: "text-davinci-003",
                prompt: prompt,
                max_tokens: Tokens.max_text_output_count(opts),
                temperature: 0
              )

            text
        end

      [title, summary] = String.split(text, "|")

      range =
        TsRange.new(
          DateSupport.start_of_day(first_statement.occurred_at, opts),
          DateSupport.end_of_day(last_statement.occurred_at, opts)
        )

      summary_attrs = %{
        title: String.trim(title),
        content: String.trim(summary),
        chunker: :daily,
        level: Summary.daily(),
        summarizer_id: summarizer.id,
        tsrange: range,
        time_zome: Keyword.get(opts, :timezone, "Etc/UTC"),
        conversation_summarizer_id: conversation_summarizer_id
      }

      Summaries.create_summary(summary_attrs)
      |> case do
        {:ok, summary} ->
          Logger.info("Created summary #{summary.id}")

          statement_summaries =
            Enum.map(statements, fn statement ->
              {:ok, statement_summary} =
                %{level: Summary.daily(), statement_id: statement.id, summary_id: summary.id}
                |> StatementSummaries.create_statement_summary()

              statement_summary
            end)

          Map.put(summary, :statement_summaries, statement_summaries)

        {:error, changeset} ->
          Logger.error("Failed to create summary", errors: changeset.errors)
      end
    end)
  end

  def create_weekly_summaries(
        %Conversation{} = conversation,
        %Summarizer{} = summarizer,
        opts \\ []
      ) do
    filters =
      Summaries.list_summaries(
        order_by: [summary_interval_lower: :desc],
        filters: [conversation_id: conversation.id, level: Summary.weekly()],
        limit: 1
      )
      |> case do
        [] ->
          [filters: [level: Summary.daily(), conversation_id: conversation.id]]

        [%Summary{summary_interval: %{upper: upper}}] ->
          [filters: [level: Summary.daily(), after: upper, conversation_id: conversation.id]]
      end

    case Summaries.list_summaries(filters) do
      summaries when summaries == [] ->
        []

      summaries ->
        first_summary = Enum.at(summaries, 0)
        last_summary = Enum.at(summaries, -1)

        summaries
        |> Chunker.apply(chunkers: [:weekly])
        |> Enum.map(fn summaries ->
          text = join_content(summaries)

          prompt = Chunker.prompt(:weekly, text, opts)

          {:ok, text} =
            create_completion(
              model: "text-davinci-003",
              prompt: prompt,
              max_tokens: Tokens.max_text_output_count(opts),
              temperature: 0
            )

          [title, summary] = String.split(text, "|")

          range =
            TsRange.new(
              DateSupport.beginning_of_week(first_summary.summary_interval, opts),
              DateSupport.end_of_week(last_summary.summary_interval, opts)
            )

          summary_attrs = %{
            title: String.trim(title),
            content: String.trim(summary),
            chunker: :weekly,
            level: Summary.weekly(),
            summarizer_id: summarizer.id,
            tsrange: range,
            time_zome: Keyword.get(opts, :timezone, "Etc/UTC")
          }

          Summaries.create_summary(summary_attrs)
          |> case do
            {:ok, weekly_summary} ->
              summaries =
                Enum.map(summaries, fn summary ->
                  {:ok, updated_summary} =
                    Summaries.update_summary(summary, %{summary_id: weekly_summary.id})

                  updated_summary
                end)

              Map.put(weekly_summary, :summaries, summaries)

            {:error, changeset} ->
              Logger.error("Failed to create summary", errors: changeset.errors)
          end
        end)
    end
  end

  defp join_content(items) do
    Enum.reduce(items, "", fn
      %Statement{} = statement, acc ->
        "#{acc} #{Statement.render_for_prompt(statement)}"

      %Summary{} = summary, acc ->
        "#{acc} #{Summary.render_for_prompt(summary)}"
    end)
  end

  defp create_completion(opts) do
    OpenAI.completions(opts)
    |> case do
      {:ok, %{choices: [%{"text" => text}]}} ->
        {:ok, text}

      {:error, %{error: %{"message" => message}}} ->
        {:error, message}
    end
  end
end
