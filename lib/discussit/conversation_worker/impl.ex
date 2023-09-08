defmodule Discussit.ConversationWorker.Impl do
  alias Discussit.ConversationSummarizers
  alias Discussit.ConversationSummarizers.ConversationSummarizer
  alias Discussit.Conversations.Conversation
  alias Discussit.Summarizers
  alias Discussit.Summarizers.Summarizer
  alias Discussit.DateSupport
  alias Discussit.Statements
  alias Discussit.Chunker
  alias Discussit.Summaries
  alias Discussit.Summaries.Summary
  alias Discussit.Summaries.Summarize
  alias Discussit.Calls.Call
  alias Discussit.Transcription.Support

  def transcribe_call(call_ids, conversation, opts) do
    call_ids
    |> Flow.from_enumerable()
    |> Flow.map(&Support.get_data(%{call_id: &1, conversation: conversation}, %Call{}))
    |> Flow.map(&Support.prepare_files/1)
    |> Flow.map(&Support.transcribe(&1, opts))
    |> Flow.map(&Support.ignore_segments/1)
    |> Flow.map(&Support.build_statement_attrs/1)
    |> Flow.map(&Support.group_statement_attrs/1)
    |> Flow.map(&Support.create_statements/1)
    |> Flow.map(&Support.update_data/1)
    |> Enum.map(&Support.prepare_return/1)
  end

  def create_daily_summaries(
        %ConversationSummarizer{
          conversation: %Conversation{} = conversation,
          summarizer: %Summarizer{} = summarizer
        } = conversation_summarizer,
        opts
      ) do
    opts = Summarize.cast_opts(opts, conversation_summarizer)

    Statements.list_statements(
      filters: [
        conversation_id: conversation.id,
        not_summarizer_id: summarizer.id,
        before: DateSupport.start_of_today(opts)
      ],
      preloads: [
        participant: [:phone_number, :contact]
      ],
      order_by: [occurred_at: :asc]
    )
    |> Chunker.apply(opts)
    |> Summarize.map_summarize(opts)
    |> Enum.map(&Map.put(&1, :conversation_summarizer, conversation_summarizer))
  end

  def create_weekly_summaries(
        %ConversationSummarizer{
          conversation: %Conversation{} = conversation,
          summarizer: %Summarizer{}
        } = conversation_summarizer,
        opts
      ) do
    opts = Summarize.cast_opts(opts, conversation_summarizer)

    case Summaries.get_latest_summary!(conversation.id, Summary.weekly()) do
      nil ->
        [
          order_by: [summary_interval_lower: :asc],
          filters: [
            level: Summary.daily(),
            conversation_id: conversation.id,
            before: DateSupport.beginning_of_week(NaiveDateTime.utc_now(), opts)
          ]
        ]

      %Summary{summary_interval: %{upper: upper}} ->
        [
          order_by: [summary_interval_lower: :asc],
          filters: [
            level: Summary.daily(),
            after: upper,
            before: DateSupport.beginning_of_week(NaiveDateTime.utc_now(), opts),
            conversation_id: conversation.id
          ]
        ]
    end
    |> Summaries.list_summaries()
    |> Chunker.apply(opts)
    |> Summarize.map_summarize(opts)
    |> Enum.map(&Map.put(&1, :conversation_summarizer, conversation_summarizer))
  end

  def create_monthly_summaries(
        %ConversationSummarizer{
          conversation: %Conversation{} = conversation,
          summarizer: %Summarizer{}
        } = conversation_summarizer,
        opts
      ) do
    opts = Summarize.cast_opts(opts, conversation_summarizer)

    case Summaries.get_latest_summary!(conversation.id, Summary.monthly()) do
      nil ->
        [
          order_by: [summary_interval_lower: :asc],
          filters: [
            level: Summary.daily(),
            conversation_id: conversation.id,
            before: DateSupport.beginning_of_month(NaiveDateTime.utc_now(), opts)
          ]
        ]

      %Summary{summary_interval: %{upper: upper}} ->
        [
          order_by: [summary_interval_lower: :asc],
          filters: [
            level: Summary.daily(),
            after: upper,
            before: DateSupport.beginning_of_month(NaiveDateTime.utc_now(), opts),
            conversation_id: conversation.id
          ]
        ]
    end
    |> Summaries.list_summaries()
    |> Chunker.apply(opts)
    |> Summarize.map_summarize(opts)
    |> Enum.map(&Map.put(&1, :conversation_summarizer, conversation_summarizer))
  end

  def create_yearly_summaries(
        %ConversationSummarizer{
          conversation: %Conversation{} = conversation,
          summarizer: %Summarizer{}
        } = conversation_summarizer,
        opts
      ) do
    opts = Summarize.cast_opts(opts, conversation_summarizer)

    case Summaries.get_latest_summary!(conversation.id, Summary.yearly()) do
      nil ->
        [
          filters: [
            level: Summary.monthly(),
            conversation_id: conversation.id,
            before: DateSupport.beginning_of_month(NaiveDateTime.utc_now(), opts)
          ]
        ]

      %Summary{summary_interval: %{upper: upper}} ->
        [
          filters: [
            level: Summary.weekly(),
            after: upper,
            before: DateSupport.beginning_of_month(NaiveDateTime.utc_now(), opts),
            conversation_id: conversation.id
          ]
        ]
    end
    |> Summaries.list_summaries()
    |> Chunker.apply(opts)
    |> Summarize.map_summarize(opts)
    |> Enum.map(&Map.put(&1, :conversation_summarizer, conversation_summarizer))
  end

  def ensure_conversation_summarizers_exist(%{conversation: conversation}) do
    ["daily", "weekly", "monthly", "yearly"]
    |> Enum.map(&Summarizers.get_summarizer_by!(name: &1))
    |> Enum.map(
      &%{
        s: &1,
        cs:
          ConversationSummarizers.get_conversation_summarizer_by(%{
            conversation_id: conversation.id,
            summarizer_id: &1.id
          })
      }
    )
    |> Enum.map(fn
      %{cs: nil, s: %{id: summarizer_id} = summarizer} ->
        ConversationSummarizers.create_conversation_summarizer(%{
          summarizer_id: summarizer_id,
          conversation_id: conversation.id
        })
        |> case do
          {:ok, cs} -> load(cs, conversation, summarizer)
          {:error, _} -> :error
        end

      %{cs: %ConversationSummarizer{} = cs, s: summarizer} ->
        load(cs, conversation, summarizer)
    end)
  end

  defp load(conversation_summarizer, conversation, summarizer),
    do:
      conversation_summarizer
      |> Map.put(:summarizer, summarizer)
      |> Map.put(:conversation, conversation)

  def broadcast_busy(%{conversation: conversation}) do
    conversation
    |> name()
    |> Atom.to_string()
    |> DiscussitWeb.Endpoint.broadcast("busy", nil)
  end

  def broadcast_idle(%{conversation: conversation}) do
    conversation
    |> name()
    |> Atom.to_string()
    |> DiscussitWeb.Endpoint.broadcast("idle", nil)
  end

  def name(%Conversation{id: id}), do: name(id)
  def name(id), do: :"conversation_#{id}"
end
