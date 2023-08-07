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

  @impl true
  def mount(_params, _session, socket) do
    conversations =
      socket.assigns.user_setting.selected_account_id
      |> Conversations.list_conversation_summary(limit: 20)

    {:ok,
     socket
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
