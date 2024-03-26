defmodule Discussit.ConversationSummarizers.Task do
  @max_attempts 3

  alias Discussit.ConversationSummarizers.ConversationSummarizer

  use Oban.Worker,
    queue: :conversation_summarizer,
    unique: [fields: [:args]]

  alias Discussit.ConversationSummarizers
  @impl Oban.Worker
  def perform(%Oban.Job{args: args, attempt: @max_attempts} = job) do
    %{"account_id" => account_id} = args
    job = Map.put(job, :state, "discarded")
    broadcast(job, account_id)
    {:cancel, "max_attempts reached"}
  end

  def perform(%Oban.Job{args: args} = job) do
    %{"account_id" => account_id} = args
    broadcast(job, account_id)
    do_perform(job)
  end

  def do_perform(%Oban.Job{args: args} = job) do
    %{
      "conversation_summarizer_id" => cs_id,
      "account_id" => account_id
    } = args

    with %ConversationSummarizer{} = cs <- get_conversation_summarizer!(cs_id),
         _cs <- create_custom_summary(cs, account_id),
         broadcast(Map.put(job, :state, "completed"), account_id) do
      :ok
    end
  end

  defp get_conversation_summarizer!(id),
    do:
      ConversationSummarizers.get_conversation_summarizer!(id,
        preloads: [:conversation, [summarizer: :model]]
      )

  defp create_custom_summary(cs, account_id),
    do: Discussit.ConversationWorker.Impl.create_custom_summary(cs, account_id: account_id)

  defp broadcast(cs, account_id),
    do:
      DiscussitWeb.Endpoint.broadcast(
        "account_#{account_id}",
        "conversation_summarizer_job_updated",
        cs
      )
end
