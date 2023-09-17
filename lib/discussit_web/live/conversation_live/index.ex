defmodule DiscussitWeb.ConversationLive.Index do
  use DiscussitWeb, :live_view

  alias Discussit.Conversations

  @impl true
  def mount(_params, _session, socket) do
    conversations =
      [filters: [account_id: socket.assigns.current_user.selected_account_id]]
      |> Conversations.list_conversations()

    {:ok, stream(socket, :conversations, conversations)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Conversations")
    |> assign(:conversation, nil)
  end
end
