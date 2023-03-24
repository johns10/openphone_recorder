defmodule OpenphoneRecorderWeb.ConversationLive.Show do
  use OpenphoneRecorderWeb, :live_view

  alias OpenphoneRecorder.Conversations

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:conversation, Conversations.get_conversation!(id))}
  end

  defp page_title(:show), do: "Show Conversation"
end
