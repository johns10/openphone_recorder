defmodule OpenphoneRecorderWeb.SummarizerLive.Show do
  use OpenphoneRecorderWeb, :live_view

  alias OpenphoneRecorder.Summarizers

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:summarizer, Summarizers.get_summarizer!(id))}
  end

  defp page_title(:show), do: "Show Summarizer"
  defp page_title(:edit), do: "Edit Summarizer"
end
