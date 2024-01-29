defmodule DiscussitWeb.SummarizerLive.Index do
  use DiscussitWeb, :live_view

  alias Discussit.Summarizers
  alias Discussit.Summarizers.Summarizer

  @impl true
  def mount(_params, _session, socket) do
    account_id = socket.assigns.current_user.selected_account_id

    summarizers =
      Summarizers.list_summarizers(filters: [nil_account_id: true]) ++
        Summarizers.list_summarizers(filters: [account_id: account_id])

    {:ok, stream(socket, :summarizers, summarizers), layout: {DiscussitWeb.Layouts, :full_screen}}
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
  def handle_info({DiscussitWeb.SummarizerLive.FormComponent, {:saved, summarizer}}, socket) do
    {:noreply, stream_insert(socket, :summarizers, summarizer)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    summarizer = Summarizers.get_summarizer!(id)
    {:ok, _} = Summarizers.delete_summarizer(summarizer)

    {:noreply, stream_delete(socket, :summarizers, summarizer)}
  end
end
