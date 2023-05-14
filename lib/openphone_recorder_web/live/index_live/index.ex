defmodule OpenphoneRecorderWeb.IndexLive.Index do
  use OpenphoneRecorderWeb, :live_view
  use Phoenix.LiveView,
    container: {:div, class: "h-full flex-grow flex flex-col"}

  import OpenphoneRecorderWeb.IndexLive.Components

  alias OpenphoneRecorder.Conversations

  @impl true
  def mount(_params, _session, socket) do
    conversations = Conversations.list_conversation_summary()
    conversations
    {:ok,
    stream(socket, :conversations, conversations),
    layout: {OpenphoneRecorderWeb.Layouts, :full_screen}}
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
