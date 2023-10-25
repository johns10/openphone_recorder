defmodule DiscussitWeb.TopicLive.Index do
  use DiscussitWeb, :live_view

  alias Discussit.Topics
  alias Discussit.Topics.Topic

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :topics, Topics.list_topics())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Topic")
    |> assign(:topic, Topics.get_topic!(id))
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Topics")
    |> assign(:topic, nil)
  end

  @impl true
  def handle_info({DiscussitWeb.TopicLive.FormComponent, {:saved, topic}}, socket) do
    {:noreply, stream_insert(socket, :topics, topic)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    topic = Topics.get_topic!(id)
    {:ok, _} = Topics.delete_topic(topic)

    {:noreply, stream_delete(socket, :topics, topic)}
  end
end
