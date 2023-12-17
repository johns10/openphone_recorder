defmodule DiscussitWeb.TopicLive.Migrate do
  use DiscussitWeb, :live_view
  alias Discussit.Topics
  alias Discussit.Topics.{Keywords, Topic}
  import DiscussitWeb.TopicLive.Components

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket, layout: {DiscussitWeb.Layouts, :full_screen}}
  end

  @impl true
  def handle_params(%{"id" => id, "model_id" => model_id}, _, socket) do
    account = socket.assigns.current_user.selected_account
    topic = get_topic!(id)

    to_topic_id =
      topic
      |> Map.get(:to_topic, %{})
      |> case do
        nil -> nil
        map -> Map.get(map, :id, nil)
      end

    new_topics =
      [filters: [account_id: account.id, model_id: model_id]]
      |> Topics.list_topics()

    new_topics =
      Keywords.topic_scores(topic, new_topics)
      |> Enum.filter(&(&1.score > 0.0))

    {:noreply,
     socket
     |> assign(:page_title, "Migrate Topic")
     |> assign(:topic_id, id)
     |> assign(:to_topic_id, to_topic_id)
     |> assign(:model_id, model_id)
     |> assign(:topic, topic)
     |> assign(:new_topics, new_topics)}
  end

  @impl true
  def handle_event("select-to-topic", %{"topic-id" => to_topic_id}, socket) do
    case Topics.get_topic_by(%{from_topic_id: socket.assigns.topic.id}) do
      nil -> nil
      %Topic{} = topic -> Topics.update_topic(topic, %{from_topic_id: nil})
    end

    to_topic_id
    |> Topics.get_topic!()
    |> Topics.update_topic(%{from_topic_id: socket.assigns.topic.id})
    |> case do
      {:ok, _topic} ->
        {:noreply,
         socket
         |> assign(:topic, get_topic!(socket.assigns.topic.id))
         |> assign(:to_topic_id, String.to_integer(to_topic_id))}

      {:error, _changeset} ->
        {:noreply, socket}
    end
  end

  def handle_event("unmatch", _, socket) do
    case Topics.get_topic_by(%{from_topic_id: socket.assigns.topic.id}) do
      nil -> nil
      %Topic{} = topic -> Topics.update_topic(topic, %{from_topic_id: nil})
    end
    |> case do
      {:ok, _topic} ->
        {:noreply,
         socket
         |> assign(:topic, get_topic!(socket.assigns.topic.id))
         |> assign(:to_topic_id, nil)}

      {:error, _changeset} ->
        {:noreply, socket}
    end
  end

  defp get_topic!(id), do: Topics.get_topic!(id, preload: [:to_topic])
end
