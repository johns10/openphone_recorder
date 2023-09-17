defmodule DiscussitWeb.IndexLive.Index do
  alias Discussit.Meetings
  use DiscussitWeb, :html_helpers

  use Phoenix.LiveView,
    container: {:div, class: "h-full flex-grow flex flex-col overflow-hidden"}

  on_mount({DiscussitWeb.UserAuth, :mount_current_user})

  import DiscussitWeb.IndexLive.Components

  alias Discussit.Conversations
  alias Discussit.Calls
  alias Discussit.Statements
  alias Discussit.Participants
  alias Discussit.ConversationWorker
  alias Discussit.Summaries.Summary

  @impl true
  def mount(_, _, %{assigns: %{current_user: %{selected_account_id: nil}}} = socket) do
    {:ok,
     socket
     |> assign(:zoom_level, 0)
     |> assign(:transcription_status, %{error: 0, in_progress: 0, success: 0, not_started: 1})
     |> assign(conversations_per_page: 20, conversation_page: 1)
     |> assign(:conversation, nil)
     |> assign(:conversation_id, nil)
     |> stream(:conversations, [])
     |> assign(:end_of_timeline?, false)
     |> assign(:worker_busy?, true)
     |> stream(:conversation_items, []), layout: {DiscussitWeb.Layouts, :full_screen}}
  end

  def mount(_params, _session, socket) do
    conversations =
      socket.assigns.current_user.selected_account_id
      |> Conversations.list_conversation_summary(limit: 20)

    {:ok,
     socket
     |> assign(:zoom_level, 0)
     |> assign(:transcription_status, %{error: 0, in_progress: 0, success: 0, not_started: 1})
     |> assign(conversations_per_page: 20, conversation_page: 1)
     |> assign(:conversation, nil)
     |> assign(:conversation_id, nil)
     |> stream(:conversations, conversations)
     |> assign(:end_of_timeline?, false)
     |> assign(:worker_busy?, true)
     |> stream(:conversation_items, []), layout: {DiscussitWeb.Layouts, :full_screen}}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  @impl true
  def handle_event(_, _, %{assigns: %{current_user: %{selected_account_id: nil}}} = socket),
    do: {:noreply, socket}

  def handle_event("summarize", _, socket) do
    ConversationWorker.run_summarizers(socket.assigns.conversation)

    {:noreply, socket}
  end

  def handle_event("zoom", %{"zoom" => "0"}, socket) do
    {:noreply, replace_conversation_items(socket, socket.assigns.conversation.id)}
  end

  def handle_event("zoom", %{"zoom" => zoom}, socket) do
    level = String.to_integer(zoom)

    summaries =
      Discussit.Summaries.list_summaries(
        filters: [
          conversation_id: socket.assigns.conversation.id,
          level: level
        ],
        preload: [conversation_summarizer: :summarizer]
      )

    conversation_items =
      map_summaries_to_conversation_items(summaries)
      |> Enum.sort(&(NaiveDateTime.compare(&1.timestamp, &2.timestamp) != :gt))

    {:noreply,
     socket
     |> stream(:conversation_items, conversation_items, reset: true)
     |> assign(:zoom_level, level)}
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

  def handle_event("transcribe", %{"call-id" => call_id}, socket) do
    ConversationWorker.transcribe_call(socket.assigns.conversation, call_id)

    {:noreply, socket}
  end

  def handle_event("transcribe_conversation_calls", _, socket) do
    ids =
      Calls.list_calls(
        filters: [conversation_id: socket.assigns.conversation.id, status: :file_uploaded]
      )
      |> Enum.map(& &1.id)

    ConversationWorker.transcribe_calls(socket.assigns.conversation, ids)

    {:noreply, socket}
  end

  defp apply_action(%{assigns: %{current_user: %{selected_account_id: nil}}} = socket, _, _),
    do: socket

  defp apply_action(socket, :index, %{"id" => conversation_id}) do
    user = socket.assigns.current_user

    conversation =
      Conversations.get_conversation_summary!(
        conversation_id,
        socket.assigns.current_user.selected_account_id
      )

    conversation
    |> ConversationWorker.name()
    |> Atom.to_string()
    |> DiscussitWeb.Endpoint.subscribe()

    if socket.assigns.conversation,
      do:
        socket.assigns.conversation
        |> ConversationWorker.name()
        |> Atom.to_string()
        |> DiscussitWeb.Endpoint.unsubscribe()

    case Bodyguard.permit(Conversations, :get_conversation!, user, conversation) do
      :ok ->
        ConversationWorker.new(%{
          conversation: conversation,
          account: socket.assigns.current_user.selected_account
        })

        ConversationWorker.get_conversation_summarizers(conversation)
        ConversationWorker.busy?(conversation)

        socket
        |> replace_conversation_items(conversation_id)
        |> assign(:page_title, "Listing Conversations")
        |> assign(:conversation, conversation)
        |> assign(:conversation_id, conversation.id)
        |> assign_transcription_status(conversation_id)

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
    |> assign(:conversation_id, nil)
  end

  @impl true
  def handle_info(_, %{assigns: %{current_user: %{selected_account_id: nil}}} = socket),
    do: {:noreply, socket}

  def handle_info({_, {:account_picked, current_user}}, socket) do
    conversations =
      current_user.selected_account_id
      |> Conversations.list_conversation_summary()

    {:noreply,
     socket
     |> stream(:conversations, conversations, reset: true)
     |> stream(:conversation_items, [], reset: true)
     |> assign(:current_user, current_user)
     |> push_patch(to: ~p"/home")}
  end

  def handle_info(%{event: "busy"}, socket),
    do: {:noreply, socket |> assign(:worker_busy?, true) |> push_event("worker_busy", %{})}

  def handle_info(%{event: "idle"}, socket),
    do: {:noreply, socket |> assign(:worker_busy?, false) |> push_event("worker_idle", %{})}

  def handle_info(
        %{event: "summary_created", payload: %Summary{level: level} = summary},
        socket
      ) do
    summary = Discussit.Repo.preload(summary, conversation_summarizer: :summarizer)

    case level == socket.assigns.zoom_level do
      false ->
        {:noreply, socket}

      true ->
        conversation_item = map_summary_to_conversation_item(summary)
        {:noreply, stream_insert(socket, :conversation_items, conversation_item, at: -1)}
    end
  end

  def handle_info(
        %{event: "call_transcription_progress", payload: %{status: :transcribing} = call},
        socket
      ) do
    ended = %{
      type: "call_ended",
      data: call,
      timestamp: call.completed_at,
      id: "call-completed-#{call.id}"
    }

    {:noreply,
     socket
     |> stream_insert(:conversation_items, ended)
     |> assign_transcription_status(socket.assigns.conversation.id)}
  end

  def handle_info(%{event: "call_transcription_progress", payload: %{status: _}}, socket) do
    {:noreply,
     socket
     |> replace_conversation_items(socket.assigns.conversation.id)
     |> assign_transcription_status(socket.assigns.conversation.id)}
  end

  defp append_conversations(socket, new_page) when new_page >= 1 do
    %{conversations_per_page: per_page} = socket.assigns

    conversations =
      socket.assigns.current_user.selected_account_id
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
        socket.assigns.current_user.selected_account_id
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
              started = %{
                type: "call_started",
                data: call,
                timestamp: answered_at,
                id: "call-started-#{id}"
              }

              ended = %{
                type: "call_ended",
                data: call,
                timestamp: completed_at,
                id: "call-completed-#{id}"
              }

              [started, ended | acc]
          end)

        meetings =
          [
            filters: [conversation_id: conversation_id],
            preloads: [participant: [:contact, [phone_number: :contacts]]]
          ]
          |> Meetings.list_meetings()
          |> Enum.map(fn %{id: id, occurred_at: occurred_at} = meeting ->
            %{
              type: "meeting_started",
              data: meeting,
              timestamp: occurred_at,
              id: "meeting-#{id}"
            }
          end)

        items =
          (statements ++ calls ++ meetings)
          |> Enum.sort(&(NaiveDateTime.compare(&1.timestamp, &2.timestamp) != :gt))

        socket
        |> assign(:page_title, "Listing Conversations")
        |> assign(:conversation, conversation)
        |> assign(:conversation_id, conversation.id)
        |> stream(:conversation_items, items, reset: true)
        |> assign(:zoom_level, 0)
        |> push_event("scroll", %{id: "#statements"})

      {:error, :unauthorized} ->
        socket
        |> push_patch(to: ~p"/home")
        |> put_flash(:error, "You cannot access this conversation")
    end
  end

  defp map_summaries_to_conversation_items(summaries) do
    Enum.map(summaries, &map_summary_to_conversation_item/1)
  end

  defp map_summary_to_conversation_item(summary) do
    %{
      type: "#{summary.conversation_summarizer.summarizer.name}_summary",
      data: summary,
      timestamp: summary.summary_interval.lower,
      id: "summary-#{summary.id}"
    }
  end

  defp assign_transcription_status(socket, conversation_id) do
    data = Calls.calls_status(%{conversation_id: conversation_id})
    total = Enum.reduce(data, 0, fn %{count: count}, acc -> acc + count end)

    status =
      Enum.reduce(data, %{done: 0, not_started: 0, in_progress: 0, error: 0, warning: 0}, fn
        %{count: count, status: :transcribed}, acc ->
          Map.put(acc, :done, floor(count / total * 100) + acc.done)

        %{count: count, status: :file_uploaded}, acc ->
          Map.put(acc, :not_started, floor(count / total * 100) + acc.not_started)

        %{count: count, status: :created}, acc ->
          Map.put(acc, :warning, floor(count / total * 100) + acc.warning)

        %{count: count, status: :transcribing}, acc ->
          Map.put(acc, :in_progress, floor(count / total * 100) + acc.in_progress)

        %{count: count, status: :upload_failed}, acc ->
          Map.put(acc, :error, floor(count / total * 100) + acc.error)

        %{count: count, status: :upload_empty}, acc ->
          Map.put(acc, :warning, floor(count / total * 100) + acc.warning)
      end)

    assign(socket, :transcription_status, status)
  end
end
