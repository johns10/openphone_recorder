defmodule Discussit.ConversationWorker do
  alias Discussit.Conversations.Conversation
  alias Discussit.ConversationWorker.Impl
  alias Discussit.ConversationWorker.Server

  def new(%{conversation: %Conversation{} = conversation} = state) do
    conversation
    |> Impl.name()
    |> Process.whereis()
    |> case do
      nil -> GenServer.start_link(Server, state, name: Impl.name(conversation))
      pid -> {:ok, pid}
    end
  end

  def get_conversation_summarizers(%Conversation{} = conversation) do
    conversation
    |> Impl.name()
    |> Process.whereis()
    |> GenServer.cast(:get_conversation_summarizers)
  end

  def run_summarizers(%Conversation{} = conversation) do
    conversation
    |> Impl.name()
    |> Process.whereis()
    |> GenServer.cast(:run_summarizers)
  end

  def name(%Conversation{} = conversation), do: Impl.name(conversation)
end
