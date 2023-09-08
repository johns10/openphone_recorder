defmodule DiscussitWeb.UsageLive.Index do
  use DiscussitWeb, :live_view

  alias Discussit.Usages

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :usages, Usages.list_usages())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Usages")
    |> assign(:usage, nil)
  end

  @impl true
  def handle_info({DiscussitWeb.UsageLive.FormComponent, {:saved, usage}}, socket) do
    {:noreply, stream_insert(socket, :usages, usage)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    usage = Usages.get_usage!(id)
    {:ok, _} = Usages.delete_usage(usage)

    {:noreply, stream_delete(socket, :usages, usage)}
  end
end
