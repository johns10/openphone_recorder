defmodule DiscussitWeb.TopicLive.Index do
  use DiscussitWeb, :live_view

  alias Discussit.StatusAgent
  alias Discussit.{Topics, Models}
  alias Discussit.TopicAnalyzer
  alias Discussit.TopicAnalyzer.{Workers, Status}
  import DiscussitWeb.LiveSupport

  @impl true
  def mount(_params, _session, socket) do
    account = socket.assigns.current_user.selected_account

    model =
      [filters: [account_id: account.id], order_by: [inserted_at: :desc], limit: 1]
      |> Models.list_models()
      |> Enum.at(0)

    topics = list_topics(account, model) |> init_status_agents() |> assign_status()

    DiscussitWeb.Endpoint.subscribe("account_#{account.id}")

    {:ok,
     socket
     |> stream(:topics, topics)
     |> assign(:model, model)
     |> assign(:analyzer_available?, Status.available?(account.id)),
     layout: {DiscussitWeb.Layouts, :full_screen}}
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

  def handle_info(
        %{topic: "account" <> _, event: "topic_analysis_availability"},
        socket
      ) do
    account = socket.assigns.current_user.selected_account
    model = socket.assigns.model

    {:noreply,
     socket
     |> push_patch(to: ~p"/topics")
     |> assign(:analyzer_available?, Status.available?(account.id))
     |> stream(:topics, list_topics_with_status(account, model), reset: true)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    topic = Topics.get_topic!(id)
    {:ok, _} = Topics.delete_topic(topic)

    {:noreply, stream_delete(socket, :topics, topic)}
  end

  def handle_event("discover-topics", _, socket) do
    %{account_id: socket.assigns.current_user.selected_account.id}
    |> Workers.Initialization.new()
    |> Oban.insert()

    {:noreply, socket}
  end

  def handle_event("reset-model", _, socket) do
    account = socket.assigns.current_user.selected_account
    model = socket.assigns.model

    socket =
      with :ok <- TopicAnalyzer.delete_model(account),
           :ok <- delete_topics(account) do
        socket
        |> stream(:topics, list_topics_with_status(account, model), reset: true)
        |> assign(:analyzer_available?, Status.available?(account.id))
        |> put_flash(:success, "Regenerating topics")
        |> push_patch(to: ~p"/topics")
      else
        _ ->
          socket
          |> assign(:analyzer_available?, Status.available?(account.id))
          |> put_flash(:error, "Failed to regenerate topics")
          |> push_patch(to: ~p"/topics")
      end

    {:noreply, socket}
  end

  def handle_event("regenerate-labels", _, socket) do
    account = socket.assigns.current_user.selected_account
    TopicAnalyzer.regenerate_labels(account)

    {:noreply, socket}
  end

  def handle_event("summarize-topic", %{"topic-id" => topic_id}, socket) do
    fn ->
      Topics.Summarizer.apply(topic_id, account_id(socket))
    end
    |> Task.start()

    {:noreply, socket}
  end

  @impl true
  def handle_info(%{topic: topic, event: "status_update", payload: :finished}, socket) do
    "topic_summarizer_" <> id = topic

    topic =
      Topics.get_topic!(id)
      |> Map.put(:summarizer_status, :not_started)

    {:noreply, socket |> stream_insert(:topics, topic, at: -1)}
  end

  def handle_info(%{topic: topic, event: "status_update", payload: status}, socket) do
    "topic_summarizer_" <> id = topic

    topic =
      Topics.get_topic!(id)
      |> Map.put(:summarizer_status, status)

    {:noreply, socket |> stream_insert(:topics, topic, at: -1)}
  end

  defp list_topics_with_status(account, model), do: list_topics(account, model) |> assign_status()

  defp list_topics(%{id: account_id}, %{id: model_id}),
    do: Topics.list_topics(filters: [account_id: account_id, model_id: model_id])

  defp assign_status(topics) do
    topics
    |> Enum.map(fn topic ->
      name = StatusAgent.topic_summarizer_name(topic)
      {:ok, status} = StatusAgent.get(name)
      Map.put(topic, :summarizer_status, status)
    end)
  end

  defp init_status_agents(topics) do
    Enum.map(topics, fn topic ->
      name = StatusAgent.topic_summarizer_name(topic)
      DiscussitWeb.Endpoint.subscribe(Atom.to_string(name))
      topic
    end)
  end

  defp delete_topics(account) do
    Topics.list_topics(filters: [account_id: account.id, title_is_nil: true])
    |> Enum.reduce_while(:ok, fn topic, _ ->
      case Topics.delete_topic(topic) do
        {:ok, _} -> {:cont, :ok}
        {:error, %{errors: [labelled_statements: _]}} -> {:cont, :ok}
        {:error, _} -> {:halt, :error}
      end
    end)
  end
end
