defmodule OpenphoneRecorderWeb.IndexLive.Index do
  use OpenphoneRecorderWeb, :html_helpers
  use Phoenix.LiveView,
    container: {:div, class: "h-full flex-grow flex flex-col overflow-hidden"}

  import OpenphoneRecorderWeb.IndexLive.Components

  alias OpenphoneRecorder.Conversations
  alias OpenphoneRecorder.Statements

  @default_preloads [:participants, [participants: [phone_number: :contacts]]]

  @impl true
  def mount(_params, _session, socket) do
    conversations = Conversations.list_conversation_summary()

    {:ok,
    socket
    |> stream(:conversations, conversations)
    |> stream(:statements, []),
    layout: {OpenphoneRecorderWeb.Layouts, :full_screen}}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, %{"conversation_id" => conversation_id}) do
    conversation = Conversations.get_conversation!(conversation_id, preloads: @default_preloads)
    statements = Statements.list_statements(filters: [conversation_id: conversation_id], order_by: [occurred_at: :desc])

    conversation.participants
    |> participant_sides
    socket = Enum.reduce(socket.assigns.streams.statements, socket,
      fn statement, acc ->
        stream_delete(acc, :statements, statement)
     end)

    Enum.reduce(statements, socket,
      fn statement, acc ->
        stream_insert(acc, :statements, statement)
      end)
      |> assign(:participant_sides, participant_sides(conversation.participants))
      |> assign(:page_title, "Listing Conversations")
      |> assign(:conversation, nil)
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Conversations")
    |> assign(:conversation, nil)
  end

  defp participant_sides([p1, p2 | tail]) do
    [
      {atomize(p1.id), "chat-start"},
      {atomize(p2.id), "chat-end"}
      | Enum.map(tail, & {atomize(&1.id), "chat-end"})
    ]
  end

  defp atomize(int), do: :"#{int}"
end
