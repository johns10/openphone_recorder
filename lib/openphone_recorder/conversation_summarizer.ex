defmodule OpenphoneRecorder.ConversationSummarizer do
  require Logger

  alias OpenphoneRecorder.Conversations.Conversation
  alias OpenphoneRecorder.Summarizers.Summarizer
  alias OpenphoneRecorder.Statements
  alias OpenphoneRecorder.Statements.Statement
  alias OpenphoneRecorder.Statements.Chunker
  alias OpenphoneRecorder.Summaries
  alias OpenphoneRecorder.StatementSummaries
  alias OpenphoneRecorder.Tokens

  def apply(
        %Conversation{} = conversation,
        %Summarizer{prompt: prompt} = summarizer,
        opts \\ []
      ) do
    prompt_fun = fn text -> "#{prompt} #{text}" end

    Statements.list_statements(
      filters: [
        conversation_id: conversation.id,
        not_summarizer_id: summarizer.id
      ],
      preloads: [
        participant: [phone_number: :contact]
      ],
      order_by: [occurred_at: :desc]
    )
    |> Chunker.chunk(chunker: :temporal)
    |> create_first_layer_summaries(summarizer, opts)
  end

  defp create_first_layer_summaries(chunks, summarizer, opts) do
    Enum.map(chunks, fn statements ->
      text =
        Enum.reduce(statements, "", fn statement, acc ->
          "#{acc} #{Statement.render_for_prompt(statement)}"
        end)

      prompt = Chunker.prompt(:temporal, text, opts)

      {:ok, %{choices: [%{"text" => text}]}} =
        OpenAI.completions(
          model: "text-davinci-003",
          prompt: prompt,
          max_tokens: Tokens.max_text_output_count(opts),
          temperature: 0
        )

      [title, summary] = String.split(text, "|")

      Summaries.create_summary(%{
        title: String.trim(title),
        content: String.trim(summary),
        chunker: opts[:chunker],
        level: 1,
        summarizer_id: summarizer.id
      })
      |> case do
        {:ok, summary} ->
          statement_summaries =
            Enum.map(statements, fn statement ->
              {:ok, statement_summary} =
                StatementSummaries.create_statement_summary(%{
                  chunker: opts[:chunker],
                  level: 1,
                  statement_id: statement.id,
                  summary_id: summary.id
                })

              statement_summary
            end)

          Map.put(summary, :statement_summaries, statement_summaries)

        {:error, changeset} ->
          Logger.error("Failed to create summary", errors: changeset.errors)
      end
    end)
  end
end
