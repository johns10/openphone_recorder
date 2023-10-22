defmodule DiscussitWeb.MeetingLive.Show do
  use DiscussitWeb, :live_view
  alias Discussit.Meetings

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:meeting, Meetings.get_meeting!(id, preload: [participants: :contact]))}
  end

  defp page_title(:show), do: "Show Meeting"
  defp page_title(:edit), do: "Edit Meeting"
end
