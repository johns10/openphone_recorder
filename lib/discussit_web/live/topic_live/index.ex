defmodule DiscussitWeb.TopicLive.Index do
  use DiscussitWeb, :live_view

  alias Discussit.Topics
  alias Discussit.TopicAnalyzer

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> stream(:topics, Topics.list_topics())
     |> assign(
       :model_exists?,
       TopicAnalyzer.model_exists?(socket.assigns.current_user.selected_account)
     ), layout: {DiscussitWeb.Layouts, :full_screen}}
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

  def handle_event("generate-topics", _, socket) do
    # Task.start(fn ->
    TopicAnalyzer.init(socket.assigns.current_user.selected_account)
    #  end)

    {:noreply, socket}
  end

  def handle_event("remove-topics", _, socket) do
    account = socket.assigns.current_user.selected_account

    socket =
      with :ok <- TopicAnalyzer.delete_model(account),
           :ok <- delete_topics(account) do
        socket
        |> assign(:model_exists?, TopicAnalyzer.model_exists?(account))
        |> put_flash(:success, "Regenerating topics")
        |> push_patch(to: ~p"/topics")
      else
        _ ->
          socket
          |> assign(:model_exists?, TopicAnalyzer.model_exists?(account))
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

  def delete_topics(account) do
    Topics.list_topics(filters: [account_id: account.id])
    |> Enum.reduce_while(:ok, fn topic, _ ->
      case Topics.delete_topic(topic) do
        {:ok, _} -> {:cont, :ok}
        {:error, _} -> {:halt, :error}
      end
    end)
  end
end
