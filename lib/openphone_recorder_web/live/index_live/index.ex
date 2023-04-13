defmodule OpenphoneRecorderWeb.IndexLive.Index do
  use OpenphoneRecorderWeb, :live_view

  alias OpenphoneRecorder.Conversations

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :conversations, Conversations.list_conversations())}
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
