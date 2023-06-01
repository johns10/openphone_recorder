defmodule OpenphoneRecorderWeb.SummarizerLive.Index do
  use OpenphoneRecorderWeb, :live_view

  alias OpenphoneRecorder.Summarizers
  alias OpenphoneRecorder.Summarizers.Summarizer

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :summarizers, Summarizers.list_summarizers())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Summarizer")
    |> assign(:summarizer, Summarizers.get_summarizer!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Summarizer")
    |> assign(:summarizer, %Summarizer{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Summarizers")
    |> assign(:summarizer, nil)
  end

  @impl true
  def handle_info({OpenphoneRecorderWeb.SummarizerLive.FormComponent, {:saved, summarizer}}, socket) do
    {:noreply, stream_insert(socket, :summarizers, summarizer)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    summarizer = Summarizers.get_summarizer!(id)
    {:ok, _} = Summarizers.delete_summarizer(summarizer)

    {:noreply, stream_delete(socket, :summarizers, summarizer)}
  end
end
