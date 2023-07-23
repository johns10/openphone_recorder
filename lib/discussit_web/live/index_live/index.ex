defmodule DiscussitWeb.IndexLive.Index do
  use DiscussitWeb, :html_helpers

  use Phoenix.LiveView,
    container: {:div, class: "h-full flex-grow flex flex-col overflow-hidden"}

  on_mount {DiscussitWeb.UserAuth, :mount_current_user}

  import DiscussitWeb.IndexLive.Components

  alias OpenphoneRecorder.Conversations
  alias OpenphoneRecorder.Statements
  alias OpenphoneRecorder.ConversationSummarizers

  @default_preloads [:participants, [participants: [phone_number: :contact]]]

  @impl true
  @spec mount(any, any, Phoenix.LiveView.Socket.t()) ::
          {:ok, Phoenix.LiveView.Socket.t(), [{:layout, {any, any}}, ...]}
  def mount(_params, _session, socket) do
    conversations =
      socket.assigns.user_setting.selected_account_id
      |> Conversations.list_conversation_summary()

    {:ok,
     socket
     |> assign(:zoom_level, 0)
     |> assign(:render, true)
     |> stream(:conversations, conversations)
     |> stream(:statements, []), layout: {DiscussitWeb.Layouts, :full_screen}}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  @impl true
  def handle_event("summarize", _, socket) do
    attrs = [filters: [conversation_id: socket.assigns.conversation.id, summarizer_id: 1]]
    conversation = socket.assigns.conversation
    summarizer = OpenphoneRecorder.Summarizers.get_summarizer!(1)

    conversation_summarizer =
      attrs
      |> ConversationSummarizers.get_conversation_summarizer_by()
      |> case do
        nil ->
          {:ok, cs} =
            ConversationSummarizers.create_conversation_summarizer(%{
              conversation_id: socket.assigns.conversation.id,
              summarizer_id: 1
            })

          cs

        cs ->
          cs
      end
      |> Map.put(:summarizer, summarizer)
      |> Map.put(:conversation, conversation)

    opts = [time_zone: "Etc/UTC"]

    Task.start(fn ->
      OpenphoneRecorder.ConversationSummarizer.create_daily_summaries(
        conversation_summarizer,
        opts
      )
    end)

    {:noreply, socket}
  end

  @impl true
  def handle_event("zoom_out", _, socket) do
    conversation_id = socket.assigns.conversation.id

    summaries =
      OpenphoneRecorder.Summaries.list_summaries(
        filters: [
          conversation_id: conversation_id,
          level: OpenphoneRecorder.Summaries.Summary.daily()
        ]
      )

    {:noreply,
     socket
     |> assign(:summaries, summaries)
     |> assign(:zoom_level, OpenphoneRecorder.Summaries.Summary.daily())}
  end

  def handle_event("zoom_in", _, socket) do
    {:noreply,
     socket
     |> assign(:zoom_level, 0)}
  end

  defp apply_action(socket, :index, %{"id" => conversation_id}) do
    user = socket.assigns.current_user
    conversation = Conversations.get_conversation!(conversation_id, preloads: @default_preloads)

    case Bodyguard.permit(Conversations, :get_conversation!, user, conversation) do
      :ok ->
        statements =
          Statements.list_statements(
            filters: [conversation_id: conversation_id],
            order_by: [occurred_at: :desc]
          )

        conversation.participants
        |> participant_sides

        socket =
          Enum.reduce(socket.assigns.streams.statements, socket, fn statement, acc ->
            stream_delete(acc, :statements, statement)
          end)

        Enum.reduce(statements, socket, fn statement, acc ->
          stream_insert(acc, :statements, statement)
        end)
        |> assign(:participant_sides, participant_sides(conversation.participants))
        |> assign(:page_title, "Listing Conversations")
        |> assign(:conversation, nil)

      {:error, :unauthorized} ->
        socket
        |> push_patch(to: ~p"/home")
        |> put_flash(:error, "You cannot access this conversation")
    end
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Conversations")
    |> assign(:conversation, nil)
  end

  @impl true
  def handle_info({_, {:account_picked, user_setting}}, socket) do
    conversations =
      user_setting.selected_account_id
      |> Conversations.list_conversation_summary()

    {:noreply,
     socket
     |> replace_conversations(conversations)
     |> assign(:user_setting, user_setting)
     |> assign(:conversations, conversations)
     |> push_patch(to: ~p"/home")}
  end

  defp replace_conversations(socket, conversations) do
    socket =
      Enum.reduce(socket.assigns.streams.conversations, socket, fn conversation, acc ->
        stream_delete(acc, :conversations, conversation)
      end)

    Enum.reduce(conversations, socket, fn conversation, acc ->
      stream_insert(acc, :conversations, conversation)
    end)
  end

  defp participant_sides([p1, p2 | tail]) do
    [
      {atomize(p1.id), "chat-start"},
      {atomize(p2.id), "chat-end"}
      | Enum.map(tail, &{atomize(&1.id), "chat-end"})
    ]
  end

  defp atomize(int), do: :"#{int}"
end
