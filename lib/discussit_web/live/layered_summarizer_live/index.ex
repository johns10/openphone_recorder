defmodule DiscussitWeb.LayeredSummarizerLive.Index do
  use DiscussitWeb, :live_view

  alias Discussit.LayeredSummarizers
  alias Discussit.LayeredSummarizers.LayeredSummarizer

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :layered_summarizers, LayeredSummarizers.list_layered_summarizers())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Layered summarizer")
    |> assign(:layered_summarizer, LayeredSummarizers.get_layered_summarizer!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Layered summarizer")
    |> assign(:layered_summarizer, %LayeredSummarizer{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Layered summarizers")
    |> assign(:layered_summarizer, nil)
  end

  @impl true
  def handle_info({DiscussitWeb.LayeredSummarizerLive.FormComponent, {:saved, layered_summarizer}}, socket) do
    {:noreply, stream_insert(socket, :layered_summarizers, layered_summarizer)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    layered_summarizer = LayeredSummarizers.get_layered_summarizer!(id)
    {:ok, _} = LayeredSummarizers.delete_layered_summarizer(layered_summarizer)

    {:noreply, stream_delete(socket, :layered_summarizers, layered_summarizer)}
  end
end
