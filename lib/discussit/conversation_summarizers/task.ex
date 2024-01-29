defmodule Discussit.ConversationSummarizers.Task do
  use Oban.Worker,
    queue: :conversation_summarizer,
    unique: [fields: [:args], states: [:available, :scheduled, :executing, :retryable]]

  alias Discussit.StatusAgent
  alias Discussit.ConversationSummarizers
  @impl Oban.Worker
  def perform(%Oban.Job{args: args}) do
    %{
      "conversation_summarizer_id" => conversation_summarizer_id,
      "account_id" => account_id
    } = args

    conversation_summarizer =
      ConversationSummarizers.get_conversation_summarizer!(conversation_summarizer_id,
        preloads: [:conversation, :summarizer]
      )

    name = StatusAgent.name(conversation_summarizer)
    StatusAgent.new(name)
    StatusAgent.set(name, :running)

    Discussit.ConversationWorker.Impl.create_custom_summary(conversation_summarizer,
      account_id: account_id
    )

    StatusAgent.set(name, :done)
    StatusAgent.terminate(name)

    :ok
  end
end
