defmodule DiscussitWeb.TopicLive.Index do
  # TODO: Get rid of summarizer_status
  use DiscussitWeb, :live_view

  alias Discussit.Topics.Topic
  alias Discussit.Accounts.ResetAccountModels
  alias Discussit.StatusAgent
  alias Discussit.{Topics, Models}
  alias Discussit.TopicAnalyzer.Status
  import DiscussitWeb.LiveSupport
  import DiscussitWeb.TopicLive.Components

  @impl true
  def mount(params, _session, socket) do
    account = socket.assigns.current_user.selected_account
    [latest_model, last_model] = list_latest_models(account)
    model_id = Map.get(params, "model_id", nil)

    topics =
      list_topics(account, model_id || latest_model)
      |> init_status_agents()
      |> assign_status()

    DiscussitWeb.Endpoint.subscribe("account_#{account.id}")

    {:ok,
     socket
     |> stream(:topics, topics, reset: true)
     |> assign(:latest_model, latest_model)
     |> assign(:last_model, last_model)
     |> assign_tab(params)
     |> assign(:analyzer_available?, Status.available?(account.id)),
     layout: {DiscussitWeb.Layouts, :full_screen}}
  end

  @impl true
  def handle_params(params, url, socket) do
    {:noreply,
     socket
     |> assign(:return_to, url)
     |> apply_action(socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :train, _) do
    socket
    |> assign(:page_title, "Train Model")
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Topic")
    |> assign(:topic, Topics.get_topic!(id))
  end

  defp apply_action(socket, :index, params) do
    socket
    |> assign(:page_title, "Listing Topics")
    |> assign(:tab, :index)
    |> assign(:topic, nil)
    |> assign_tab(params)
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
    model = socket.assigns.latest_model

    {:noreply,
     socket
     |> push_patch(to: ~p"/topics")
     |> assign(:analyzer_available?, Status.available?(account.id))
     |> stream(:topics, list_topics_with_status(account, model), reset: true)}
  end

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

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    topic = Topics.get_topic!(id)
    {:ok, _} = Topics.delete_topic(topic)

    {:noreply, stream_delete(socket, :topics, topic)}
  end

  def handle_event("reset-model", _, socket) do
    # TODO: Refactor to context functions
    account = socket.assigns.current_user.selected_account

    socket =
      with {:ok, model} <- ResetAccountModels.execute(account) do
        socket
        |> stream(:topics, list_topics_with_status(account, model), reset: true)
        |> assign(:analyzer_available?, Status.available?(account.id))
        |> put_flash(:success, "Reset Model")
        |> push_patch(to: ~p"/topics")
      else
        _ ->
          socket
          |> assign(:analyzer_available?, Status.available?(account.id))
          |> put_flash(:error, "Failed to reset model")
          |> push_patch(to: ~p"/topics")
      end

    {:noreply, socket}
  end

  def handle_event("regenerate-labels", _, socket) do
    {:noreply, socket}
  end

  def handle_event("confirm-topic", %{"topic-id" => id}, socket) do
    with %Topic{model_title: t, model_description: d} = topic <- Topics.get_topic!(id),
         {:ok, topic} <- Topics.update_topic(topic, %{title: t, description: d}) do
      {:noreply,
       socket
       |> stream_insert(:topics, topic, at: -1)}
    end
  end

  def handle_event("summarize-topic", %{"topic-id" => topic_id}, socket) do
    fn ->
      Topics.Summarizer.apply(topic_id, account_id(socket))
    end
    |> Task.start()

    {:noreply, socket}
  end

  defp list_latest_models(account) do
    Models.list_models(
      order_by: [inserted_at: :desc],
      filters: [account_id: account.id],
      limit: 2
    )
    |> case do
      [latest, last] -> [latest, last]
      [latest] -> [latest, nil]
      [] -> [nil, nil]
    end
  end

  defp list_topics_with_status(account, model), do: list_topics(account, model) |> assign_status()

  defp list_topics(%{id: id}, nil),
    do: Topics.list_topics(filters: [account_id: id], preload: [:to_topic])

  defp list_topics(account, %{id: model_id}), do: list_topics(account, model_id)

  defp list_topics(%{id: account_id}, model_id),
    do:
      Topics.list_topics(
        filters: [account_id: account_id, model_id: model_id],
        preload: [:to_topic]
      )

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

  defp assign_tab(socket, %{"tab" => "index"}), do: socket |> assign(:tab, :index)
  defp assign_tab(socket, %{"tab" => "migrate"}), do: socket |> assign(:tab, :migrate)
  defp assign_tab(socket, _), do: socket |> assign(:tab, :index)
end
