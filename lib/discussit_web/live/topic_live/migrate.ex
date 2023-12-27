defmodule DiscussitWeb.TopicLive.Migrate do
  use DiscussitWeb, :live_view
  alias Discussit.{Topics, Statements}
  alias Discussit.Topics.{Keywords, Topic}
  import DiscussitWeb.TopicLive.Components
  import DiscussitWeb.StatementsLive.Components

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket, layout: {DiscussitWeb.Layouts, :full_screen}}
  end

  @impl true
  def handle_params(%{"id" => id, "model_id" => model_id}, _, socket) do
    account = socket.assigns.current_user.selected_account
    %{model_id: old_model_id} = topic = get_topic!(id)

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

    old_statements = list_statements(account, id)

    new_statements =
      case to_topic_id do
        nil -> []
        to_topic_id -> list_statements(account, to_topic_id)
      end

    {:noreply,
     socket
     |> assign(:page_title, "Migrate Topic")
     |> assign(:topic_id, id)
     |> assign(:to_topic_id, to_topic_id)
     |> assign(:to_topic, nil)
     |> assign(:model_id, model_id)
     |> assign(:topic, topic)
     |> assign(:next_topic, Topics.get_next_unmigrated_topic!(topic.id, old_model_id))
     |> assign(:new_topics, new_topics)
     |> stream(:old_statements, old_statements)
     |> stream(:new_statements, new_statements)}
  end

  @impl true
  def handle_event("select-to-topic", %{"topic-id" => to_topic_id}, socket) do
    account = socket.assigns.current_user.selected_account

    case Topics.get_topic_by(%{from_topic_id: socket.assigns.topic.id}) do
      nil -> nil
      %Topic{} = topic -> Topics.update_topic(topic, %{from_topic_id: nil})
    end

    to_topic = get_topic!(to_topic_id)

    to_topic
    |> Topics.change_topic(%{from_topic_id: socket.assigns.topic.id})
    |> Ecto.Changeset.apply_action(:insert)
    |> case do
      {:ok, _to_topic} ->
        {:noreply,
         socket
         |> assign(:to_topic, to_topic)
         |> assign(:to_topic_id, String.to_integer(to_topic_id))
         |> stream(:new_statements, list_statements(account, to_topic_id), reset: true)}

      {:error, _changeset} ->
        {:noreply, socket}
    end
  end

  def handle_event("copy", _, socket) do
    from_topic = socket.assigns.topic
    to_topic = socket.assigns.to_topic

    attrs =
      from_topic
      |> Map.from_struct()
      |> Map.take([:title, :model_title, :description, :model_description])
      |> Map.put(:from_topic_id, from_topic.id)

    to_topic
    |> Topics.update_topic(attrs)
    |> case do
      {:ok, _topic} ->
        {:noreply,
         socket
         |> assign(:topic, get_topic!(socket.assigns.topic.id))}

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
         |> assign(:to_topic_id, nil)
         |> stream(:new_statements, [], reset: true)}

      {:error, _changeset} ->
        {:noreply, socket}
    end
  end

  defp get_topic!(id), do: Topics.get_topic!(id, preload: [:to_topic])

  defp list_statements(account, topic_id),
    do:
      Statements.list_statements(
        filters: [account_id: account.id, topic_id: topic_id],
        order_by: [representative: :desc],
        limit: 100
      )
end
