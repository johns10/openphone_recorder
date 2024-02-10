defmodule DiscussitWeb.MeetingLive.ShowComponent do
  use DiscussitWeb, :live_component
  import DiscussitWeb.IndexLive.Components
  alias Discussit.Conversations
  alias Discussit.Meetings
  alias Discussit.Statements
  alias Discussit.Participants

  @impl true
  def update(%{meeting: meeting} = assigns, socket) do
    statements =
      Statements.list_statements(
        filters: [meeting_id: meeting.id],
        preloads: [:participant, [participant: :contact]],
        order_by: [occurred_at: :asc]
      )

    {:ok,
     socket
     |> assign(assigns)
     |> stream(:statements, statements)
     |> assign(:conversations, [])}
  end

  def update(
        %{event: :participant_contact_set, participant: %{id: participant_id} = participant},
        socket
      ) do
    meeting = socket.assigns.meeting

    participants =
      meeting.participants
      |> Enum.map(fn
        %{id: ^participant_id} -> participant
        old -> old
      end)

    contact_ids = Enum.map(participants, & &1.contact_id)

    conversations =
      Conversations.list_conversations(
        filters: [exact_contact_ids: contact_ids],
        preloads: [participants: :contact]
      )

    statements =
      Statements.list_statements(
        filters: [meeting_id: meeting.id],
        preloads: [:participant, [participant: :contact]],
        order_by: [occurred_at: :asc]
      )

    {:ok,
     socket
     |> assign(:meeting, %{meeting | participants: participants})
     |> stream(:statements, statements, reset: true)
     |> assign(:conversations, conversations)}
  end

  @impl true
  def handle_event("assign-to-conversation", %{"id" => conversation_id}, socket) do
    meeting = socket.assigns.meeting

    Meetings.update_meeting(meeting, %{conversation_id: conversation_id})
    |> case do
      {:ok, meeting} ->
        update_meeting_statements(meeting.id, conversation_id)
        update_meeting_participants(meeting.id, conversation_id)
        {:noreply, assign(socket, :meeting, meeting)}

      {:error, _changeset} ->
        {:noreply,
         socket
         |> put_flash(:error, "Failed to assign meeting to conversation")
         |> push_patch(to: ~p"/meetings/#{meeting.id}")}
    end
  end

  def handle_event("remove-from-conversation", _, socket) do
    meeting = socket.assigns.meeting
    conversation = Conversations.get_conversation!(meeting.conversation_id)

    Meetings.update_meeting(meeting, %{conversation_id: nil})
    |> case do
      {:ok, meeting} ->
        update_meeting_statements(meeting.id, nil)
        update_meeting_participants(meeting.id, nil)
        Conversations.delete_conversation(conversation)
        {:noreply, assign(socket, :meeting, meeting)}

      {:error, _changeset} ->
        {:noreply,
         socket
         |> put_flash(:error, "Failed to remove meeting from conversation")
         |> push_patch(to: ~p"/meetings/#{meeting.id}")}
    end
  end

  def handle_event("create-conversation", _, socket) do
    meeting = socket.assigns.meeting

    meeting
    |> Map.from_struct()
    |> Map.take([:external_id, :source, :occurred_at])
    |> Map.put(:account_id, socket.assigns.current_user.selected_account_id)
    |> Conversations.create_conversation()
    |> case do
      {:ok, conversation} ->
        {:ok, meeting} = Meetings.update_meeting(meeting, %{conversation_id: conversation.id})
        update_meeting_statements(meeting.id, conversation.id)
        update_meeting_participants(meeting.id, conversation.id)
        {:noreply, socket |> assign(:meeting, meeting)}

      {:error, _changeset} ->
        {:noreply,
         socket
         |> put_flash(:error, "Failed to create conversation for meeting")
         |> push_patch(to: ~p"/meetings/#{meeting.id}")}
    end
  end

  defp update_meeting_statements(meeting_id, conversation_id) do
    Statements.list_statements(filters: [meeting_id: meeting_id])
    |> Enum.map(fn statement ->
      {:ok, _} = Statements.update_statement(statement, %{conversation_id: conversation_id})
    end)
  end

  defp update_meeting_participants(meeting_id, conversation_id) do
    Participants.list_participants(filters: [meeting_id: meeting_id])
    |> Enum.map(fn participant ->
      {:ok, _} = Participants.update_participant(participant, %{conversation_id: conversation_id})
    end)
  end

  defp all_participants_assigned?(meeting),
    do: Enum.all?(meeting.participants, &(&1.contact_id != nil))

  defp render_conversation_name(participants), do: render_conversation_name("", participants)

  defp render_conversation_name(acc, [%{contact: contact}]), do: acc <> render_name(contact)

  defp render_conversation_name(acc, [%{contact: contact} | participants]),
    do: render_conversation_name(acc <> render_name(contact) <> ", ", participants)

  defp render_name(%{first_name: first_name, last_name: last_name}),
    do: first_name <> if(last_name && last_name != "", do: " #{last_name}", else: "")
end
