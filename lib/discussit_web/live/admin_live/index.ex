defmodule DiscussitWeb.AdminLive.Index do
  use DiscussitWeb, :live_view

  alias Discussit.Events.Consumer

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true

  def handle_event("set_count", %{"count" => "infinity"}, socket) do
    Consumer.set_count(:inf)

    {:noreply, socket}
  end

  def handle_event("set_count", %{"count" => count}, socket) do
    count
    |> String.to_integer()
    |> Consumer.set_count()

    {:noreply, socket}
  end

  def handle_event("start", _, socket) do
    Consumer.start()

    {:noreply, socket}
  end
end
