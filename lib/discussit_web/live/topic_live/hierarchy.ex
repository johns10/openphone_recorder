defmodule DiscussitWeb.TopicLive.Hierarchy do
  # TODO: Get rid of summarizer_status
  use DiscussitWeb, :live_view

  alias Discussit.Topics
  alias Discussit.TopicAnalyzer.Status
  import DiscussitWeb.TopicLive.Components
  import DiscussitWeb.TopicLive.Support

  @impl true
  def mount(params, _session, socket) do
    account = socket.assigns.current_user.selected_account
    [latest_model, last_model] = list_latest_models(account)
    model_id = Map.get(params, "model_id", latest_model.id)

    topic =
      Topics.list_topics(filters: [account_id: account.id, model_id: model_id])
      |> Enum.filter(&(&1.topic_model_id != -1))
      |> Enum.map(&Map.put(&1, :child_topics, []))
      |> nest_topics()

    {:ok,
     socket
     |> assign(:topic, topic)
     |> assign(:latest_model, latest_model)
     |> assign(:last_model, last_model)
     |> assign(:tab, :hierarchy)
     |> assign(:analyzer_available?, Status.available?(account.id)),
     layout: {DiscussitWeb.Layouts, :full_screen}}
  end

  @impl true
  def handle_event("merge-topic", %{"topic-id" => topic_id}, socket) do
    account_id = socket.assigns.current_user.selected_account_id

    Topics.list_topics(filters: [account_id: account_id, leaves: topic_id, hierarchy?: false])
    |> Enum.filter(&(&1.id != String.to_integer(topic_id)))
    |> Enum.map(& &1.topic_model_id)

    {:noreply, socket}
  end
end
