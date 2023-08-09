defmodule DiscussitWeb.IndexLive.Index do
  use DiscussitWeb, :html_helpers

  use Phoenix.LiveView,
    container: {:div, class: "h-full flex-grow flex flex-col overflow-hidden"}

  on_mount({DiscussitWeb.UserAuth, :mount_current_user})

  import DiscussitWeb.IndexLive.Components
  import DiscussitWeb.LiveSupport

  alias Discussit.Conversations
  alias Discussit.Calls
  alias Discussit.Statements
  alias Discussit.Participants
  alias Discussit.UserSettings.UserSetting
  alias OpenphoneRecorder.ConversationSummarizers

  @impl true
  @spec mount(any, any, Phoenix.LiveView.Socket.t()) ::
          {:ok, Phoenix.LiveView.Socket.t(), [{:layout, {any, any}}, ...]}
  def mount(_params, _session, socket) do
    conversations =
      socket.assigns.user_setting.selected_account_id
      |> Conversations.list_conversation_summary(limit: 20)

    {:ok,
     socket
     |> assign(:zoom_level, 0)
     |> assign(conversations_per_page: 20, conversation_page: 1)
     |> assign(:conversation, nil)
     |> stream(:conversations, conversations)
     |> assign(end_of_timeline?: false)
     |> stream(:conversation_items, []), layout: {DiscussitWeb.Layouts, :full_screen}}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  @impl true
<<<<<<< HEAD
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

  def handle_event(
        "set-participant-contact",
        %{"contact-id" => contact_id, "participant-id" => participant_id},
        socket
      ) do
    Participants.get_participant!(participant_id)
    |> Participants.update_participant(%{contact_id: contact_id})
    |> case do
      {:ok, _participant} ->
        %{assigns: %{conversation: conversation}} =
          socket = replace_conversation_items(socket, socket.assigns.conversation.id)

        {:noreply, stream_insert(socket, :conversations, conversation)}

      _ ->
        {:noreply, socket}
    end
  end

  def handle_event("next-page", _, socket) do
    {:noreply, append_conversations(socket, socket.assigns.conversation_page + 1)}
  end

  defp apply_action(socket, :index, %{"id" => conversation_id}) do
    replace_conversation_items(socket, conversation_id)
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
     |> stream(:conversations, conversations, reset: true)
     |> stream(:conversation_items, [], reset: true)
     |> assign(:user_setting, user_setting)
     |> push_patch(to: ~p"/home")}
  end

  defp append_conversations(socket, new_page) when new_page >= 1 do
    %{conversations_per_page: per_page, conversation_page: cur_page} = socket.assigns

    conversations =
      socket.assigns.user_setting.selected_account_id
      |> Conversations.list_conversation_summary(
        offset: (new_page - 1) * per_page,
        limit: per_page
      )

    case conversations do
      [] ->
        assign(socket, end_of_timeline?: true)

      [_ | _] = conversations ->
        socket
        |> assign(end_of_timeline?: false)
        |> assign(:conversation_page, new_page)
        |> stream(:conversations, conversations, at: -1)
    end
  end

  defp replace_conversation_items(socket, conversation_id) do
    user = socket.assigns.current_user

    conversation =
      Conversations.get_conversation_summary!(
        conversation_id,
        socket.assigns.user_setting.selected_account_id
      )

    case Bodyguard.permit(Conversations, :get_conversation!, user, conversation) do
      :ok ->
        statements =
          Statements.list_statements(
            filters: [conversation_id: conversation_id],
            preloads: [:participant, [participant: [:contact, [phone_number: :contacts]]]]
          )
          |> Enum.map(
            &%{type: "statement", data: &1, id: "statement-#{&1.id}", timestamp: &1.occurred_at}
          )

        calls =
          [
            filters: [conversation_id: conversation_id],
            preloads: [
              [from_participant: [:contact, [phone_number: :contacts]]],
              [to_participant: [:contact, [phone_number: :contacts]]]
            ]
          ]
          |> Calls.list_calls()
          |> Enum.reduce([], fn
            %{answered_at: nil, completed_at: timestamp, id: id} = call, acc ->
              [
                %{type: "call_missed", data: call, timestamp: timestamp, id: "call-missed-#{id}"}
                | acc
              ]

            %{answered_at: answered_at, completed_at: completed_at, id: id} = call, acc ->
              [
                %{
                  type: "call_started",
                  data: call,
                  timestamp: answered_at,
                  id: "call-started-#{id}"
                },
                %{
                  type: "call_ended",
                  data: call,
                  timestamp: completed_at,
                  id: "call-completed-#{id}"
                }
                | acc
              ]
          end)

        items =
          (statements ++ calls)
          |> Enum.sort(&(NaiveDateTime.compare(&1.timestamp, &2.timestamp) != :gt))

        socket
        |> assign(:participant_sides, participant_sides(conversation.participants))
        |> assign(:page_title, "Listing Conversations")
        |> assign(:conversation, conversation)
        |> stream(:conversation_items, items, reset: true)
        |> push_event("scroll", %{id: "#statements"})

      {:error, :unauthorized} ->
        socket
        |> push_patch(to: ~p"/home")
        |> put_flash(:error, "You cannot access this conversation")
    end
  end

  defp participant_sides([p1, p2 | tail]) do
    [
      {atomize(p1.id), "chat-start pl-2"},
      {atomize(p2.id), "chat-end"}
      | Enum.map(tail, &{atomize(&1.id), "chat-end"})
    ]
  end

  defp render_date(%NaiveDateTime{} = date_time, %UserSetting{} = user_setting) do
    options = select_options(UserSetting, :timezone)
    timezone = Keyword.get(options, user_setting.timezone, "Etc/UTC")
    {:ok, local} = DateTime.from_naive(date_time, timezone)
    "#{local.month}/#{local.day} #{local.hour}:#{local.minute}"
  end

  defp atomize(int), do: :"#{int}"
end
