defmodule Discussit.Summaries.Summarize do
  require Logger

  alias Discussit.ConversationSummarizers.ConversationSummarizer
  alias Discussit.Statements.Statement
  alias Discussit.StatementSummaries
  alias Discussit.Summaries
  alias Discussit.Summaries.Summary
  alias Discussit.Tokens
  alias Discussit.Chunker
  alias PgRanges.TsRange
  alias Discussit.DateSupport
  alias Discussit.Summarizers.Summarizer

  def map_summarize(items, opts), do: Enum.map(items, &create_summary(&1, opts))

  def create_summary(item, opts) do
    item
    |> handle_summarize(opts)
    |> summary_attrs(item, opts)
    |> Summaries.create_summary()
    |> case do
      {:ok, summary} ->
        create_relationships(item, summary)
        opts[:broadcast_function].("summary_created", summary)
        summary

      {:error, _changeset} ->
        :error
    end
  end

  def cast_opts(
        opts,
        %ConversationSummarizer{
          id: conversation_summarizer_id,
          summarizer:
            %Summarizer{
              reducer_prompt: reducer_prompt,
              prompt: prompt,
              percentage_reduction: percentage_reduction,
              fixed_reduction: fixed_reduction,
              chunker: chunker
            } = summarizer
        }
      ) do
    case summarizer do
      %{percentage_reduction: nil, fixed_reduction: fixed_reduction} ->
        [
          max_output_count: fixed_reduction,
          max_context_count: 4096 - Tokens.count(prompt) - fixed_reduction
        ]

      %{percentage_reduction: percentage_reduction, fixed_reduction: nil} ->
        opts = [prompt: prompt, percentage_reduction: percentage_reduction]

        [
          max_output_count: Tokens.max_text_output_count(opts),
          max_context_count: Tokens.max_context_count(opts)
        ]
    end
    |> Keyword.merge(
      prompt: prompt,
      reducer_prompt: reducer_prompt,
      percentage_reduction: percentage_reduction,
      conversation_summarizer_id: conversation_summarizer_id,
      chunkers: [chunker],
      fixed_reduction: fixed_reduction
    )
    |> Keyword.merge(opts)
  end

  def handle_summarize(chunk, opts) do
    total_tokens = Tokens.count(chunk)

    case total_tokens > opts[:max_context_count] do
      true -> reduce(chunk, opts)
      false -> summarize(chunk, opts)
    end
  end

  def reduce(chunk, opts) do
    total_tokens = Tokens.count(chunk)
    prompt = opts[:reducer_prompt]
    percentage_reduction = opts[:max_context_count] / total_tokens

    max_output_count =
      Tokens.max_context_count(prompt: prompt, percentage_reduction: percentage_reduction)

    result =
      chunk
      |> Chunker.apply(
        chunkers: [:token_count],
        max_tokens: max_output_count
      )
      |> Enum.reduce(%{previous_summary: "", summaries: []}, fn chunk, acc ->
        max_output_count = floor(Tokens.count(chunk) * percentage_reduction)
        context = join_content(chunk)

        assigns = [
          max_output_count: max_output_count,
          context: context,
          previous_summary: acc.previous_summary
        ]

        prompt = EEx.eval_string(prompt, assigns)
        {:ok, text} = create_completion(prompt, max_output_count)

        previous_summary =
          text
          |> Gpt3Tokenizer.encode()
          |> Enum.slice(-100..-1)
          |> Gpt3Tokenizer.decode()

        acc
        |> Map.put(:previous_summary, previous_summary)
        |> Map.put(:summaries, [text | acc.summaries])
      end)

    content =
      Enum.reverse(result.summaries)
      |> join_content()

    case Gpt3Tokenizer.token_count(content) < opts[:max_output_count] + 100 do
      true ->
        content

      false ->
        summarize([content], opts)
    end
  end

  def summarize(items, opts) do
    context = join_content(items)
    prompt_template = Keyword.get(opts, :prompt)
    percentage_reduction = Keyword.get(opts, :percentage_reduction)
    max_output = Tokens.max_text_output_count(opts)

    assigns = [
      max_output_count: max_output,
      context: context,
      percentage_reduction: percentage_reduction
    ]

    prompt = EEx.eval_string(prompt_template, assigns)
    {:ok, text} = create_completion(prompt, max_output)

    text
  end

  defp summary_attrs(summary, [%Statement{} | _] = statements, opts) do
    from =
      Enum.at(statements, 0)
      |> Map.get(:occurred_at)
      |> NaiveDateTime.to_date()
      |> NaiveDateTime.new!(~T[00:00:00])

    to =
      Enum.at(statements, -1)
      |> Map.get(:occurred_at)
      |> NaiveDateTime.to_date()
      |> NaiveDateTime.new!(~T[23:59:59])

    range = TsRange.new(from, to)

    %{
      content: String.trim(summary),
      chunker: :daily,
      level: Summary.daily(),
      summarizer_id: opts[:summarizer_id],
      summary_interval: range,
      time_zome: Keyword.get(opts, :timezone, "Etc/UTC"),
      conversation_summarizer_id: opts[:conversation_summarizer_id]
    }
  end

  defp summary_attrs(summary, [%Summary{} | _] = summaries, opts) do
    first_summary = Enum.at(summaries, 0)
    last_summary = Enum.at(summaries, -1)

    range =
      case opts[:chunkers] do
        [:weekly] ->
          from =
            DateSupport.beginning_of_week(first_summary.summary_interval, opts)
            |> DateTime.to_naive()

          to =
            DateSupport.end_of_week(last_summary.summary_interval, opts)
            |> DateTime.to_naive()

          TsRange.new(from, to)

        [:monthly] ->
          from =
            DateSupport.beginning_of_month(first_summary.summary_interval, opts)
            |> DateTime.to_naive()

          to =
            DateSupport.end_of_month(last_summary.summary_interval, opts)
            |> DateTime.to_naive()

          TsRange.new(from, to)
      end

    level =
      case opts[:chunkers] do
        [:weekly] -> Summary.weekly()
        [:monthly] -> Summary.monthly()
      end

    %{
      content: String.trim(summary),
      chunker: :weekly,
      level: level,
      summarizer_id: opts[:summarizer_id],
      summary_interval: range,
      time_zome: Keyword.get(opts, :timezone, "Etc/UTC"),
      conversation_summarizer_id: opts[:conversation_summarizer_id]
    }
  end

  defp create_relationships([%Statement{} | _] = items, %Summary{id: summary_id}) do
    items
    |> Enum.map(&%{statement_id: &1.id, summary_id: summary_id})
    |> Enum.map(&StatementSummaries.create_statement_summary/1)
  end

  defp create_relationships(_, _), do: nil

  def join_content(items) do
    Enum.reduce(items, "", fn
      %Statement{} = statement, acc ->
        "#{acc} #{Statement.render_for_prompt(statement)}"

      %Summary{} = summary, acc ->
        "#{acc} #{Summary.render_for_prompt(summary)}"

      text, acc when is_binary(text) ->
        "#{acc}\n\n#{text}"
    end)
  end

  def create_completion(prompt, max_tokens) do
    messages = [
      %{role: :user, content: prompt}
    ]

    opts = [max_tokens: max_tokens, temperature: 0]

    ExOpenAI.Chat.create_chat_completion(messages, "gpt-3.5-turbo", opts)
    |> case do
      {:ok, %{choices: [%{message: %{content: content}}]}} ->
        {:ok, content}

      {:error, %{error: %{message: message}}} ->
        {:error, message}
    end
  end
end
