defmodule DiscussitWeb.TopicLive.Show do
  use DiscussitWeb, :live_view
  alias Discussit.Topics
  alias Discussit.Statements
  import DiscussitWeb.IndexLive.Components
  import DiscussitWeb.LiveSupport

  @statement_preloads [
    :model_topic,
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
    topics =
      Topics.list_topics(limit: 5)
      |> select_options()

    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:topic, Topics.get_topic!(id))
     |> stream(
       :statements,
       Statements.list_statements(
         filters: [topic_id: id],
         preloads: @statement_preloads,
         order_by: [representative: :desc]
       )
     )
     |> assign(:search_results, topics)}
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
end
