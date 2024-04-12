defmodule DiscussitWeb.LayeredSummarizerLive.Show do
  use DiscussitWeb, :live_view

  alias Discussit.LayeredSummarizers

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:layered_summarizer, LayeredSummarizers.get_layered_summarizer!(id))}
  end

  defp page_title(:show), do: "Show Layered summarizer"
  defp page_title(:edit), do: "Edit Layered summarizer"
end
