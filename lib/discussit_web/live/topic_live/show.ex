defmodule DiscussitWeb.TopicLive.Show do
  use DiscussitWeb, :live_view
  alias Discussit.Topics
  alias Discussit.Topics.Topic
  alias Discussit.Statements
  alias Discussit.StatusAgent
  import DiscussitWeb.IndexLive.Components
  import DiscussitWeb.TopicLive.Components
  import DiscussitWeb.LiveSupport

  @statement_preloads [
    :trained_topic,
    :labelled_topic,
    :participant,
    [participant: [:contact, [phone_number: :contacts]]]
  ]

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    topic = Topics.get_topic!(id)

    topics =
      Topics.list_topics(limit: 5)
      |> select_options()

    name = StatusAgent.topic_summarizer_name(topic)
    {:ok, status} = StatusAgent.get(name)
    DiscussitWeb.Endpoint.subscribe(Atom.to_string(name))

    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:topic, topic)
     |> stream(:statements, list_statements(id))
     |> assign(:search_results, topics)
     |> assign(:summarizer_status, status)}
  end

  defp page_title(:show), do: "Show Topic"
  defp page_title(:edit), do: "Edit Topic"

  @impl true
  def handle_event("search", payload, socket) do
    %{"parent_id" => statement_id, "search_phrase" => search} = payload

    topics =
      Topics.list_topics(filters: [search: search], limit: 5)
      |> select_options()

    statement = Statements.get_statement!(statement_id, preloads: @statement_preloads)

    {:noreply,
     socket
     |> assign(:search_results, topics)
     |> stream_insert(:statements, statement, at: -1)}
  end

  def handle_event("select-search-result", payload, socket) do
    %{"id" => topic_id, "parent_id" => statement_id} = payload
    topic = Topics.get_topic!(topic_id)

    {:ok, statement} =
      statement_id
      |> Statements.get_statement!(preloads: @statement_preloads)
      |> Statements.update_statement(%{labelled_topic_id: topic_id})

    statement =
      statement
      |> Map.put(:labelled_topic, topic)

    {:noreply, socket |> stream_insert(:statements, statement, at: -1)}
  end

  def handle_event("confirm-label", payload, socket) do
    %{"topic-id" => topic_id, "parent-id" => statement_id} = payload
    topic = Topics.get_topic!(topic_id)

    {:ok, statement} =
      statement_id
      |> Statements.get_statement!(preloads: @statement_preloads)
      |> Statements.update_statement(%{labelled_topic_id: topic_id})

    statement =
      statement
      |> Map.put(:labelled_topic, topic)

    {:noreply, socket |> stream_insert(:statements, statement, at: -1)}
  end

  def handle_event("summarize-topic", %{"topic-id" => topic_id}, socket) do
    fn ->
      Topics.Summarizer.apply(topic_id, account_id(socket))
    end
    |> Task.start()

    {:noreply, socket}
  end

  def handle_event("confirm-topic", %{"topic-id" => id}, socket) do
    with %Topic{model_title: t, model_description: d} = topic <- Topics.get_topic!(id),
         {:ok, topic} <- Topics.update_topic(topic, %{title: t, description: d}) do
      {:noreply,
       socket
       |> assign(:topic, topic)
       |> stream(:statements, list_statements(topic.id), reset: true)}
    end
  end

  @impl true
  def handle_info(%{event: "status_update", payload: :finished}, socket) do
    topic = Topics.get_topic!(socket.assigns.topic.id)

    {:noreply,
     socket
     |> assign(:summarizer_status, :not_started)
     |> assign(:topic, topic)
     |> stream(:statements, list_statements(topic.id), reset: true)}
  end

  def handle_info(%{event: "status_update", payload: status}, socket) do
    {:noreply, socket |> assign(:summarizer_status, status)}
  end

  def handle_info({DiscussitWeb.TopicLive.FormComponent, {:saved, topic}}, socket) do
    {:noreply, assign(socket, :topic, topic)}
  end

  defp list_statements(topic_id) do
    Statements.list_statements(
      filters: [topic_id: topic_id],
      preloads: @statement_preloads,
      order_by: [representative: :desc]
    )
  end
end
