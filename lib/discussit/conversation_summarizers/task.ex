defmodule Discussit.ConversationSummarizers.Task do
  alias Discussit.ConversationSummarizers.ConversationSummarizer

  use Oban.Worker,
    queue: :conversation_summarizer,
    unique: [fields: [:args], states: [:available, :scheduled, :executing, :retryable]]

  alias Discussit.StatusAgent
  alias Discussit.ConversationSummarizers
  @impl Oban.Worker
  def perform(%Oban.Job{args: args}) do
    %{
      "conversation_summarizer_id" => cs_id,
      "account_id" => account_id
    } = args

    with %ConversationSummarizer{} = cs <- get_conversation_summarizer!(cs_id),
         {:ok, cs} <- update_conversation_summarizer(cs, %{status: :busy}),
         broadcast(cs, account_id),
         _cs <- create_custom_summary(cs, account_id) |> IO.inspect(),
         {:ok, cs} <- update_conversation_summarizer(cs, %{status: :done}),
         broadcast(cs, account_id) do
      :ok
    end
  end

  defp get_conversation_summarizer!(id),
    do:
      ConversationSummarizers.get_conversation_summarizer!(id,
        preloads: [:conversation, :summarizer]
      )

  defp update_conversation_summarizer(cs, attrs),
    do: ConversationSummarizers.update_conversation_summarizer(cs, attrs)

  defp create_custom_summary(cs, account_id),
    do: Discussit.ConversationWorker.Impl.create_custom_summary(cs, account_id: account_id)

  defp broadcast(cs, account_id),
    do:
      DiscussitWeb.Endpoint.broadcast(
        "account_#{account_id}",
        "conversation_summarizer_updated",
        cs
      )
end
