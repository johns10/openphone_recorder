defmodule DiscussitWeb.MeetingLive.Show do
  alias Discussit.Conversations
  use DiscussitWeb, :live_view

  alias Discussit.Meetings
  import DiscussitWeb.IndexLive.Components

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    preload = [
      [participants: :contact],
      statements: [:participant, [participant: [:contact, [phone_number: :contacts]]]]
    ]

    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:meeting, Meetings.get_meeting!(id, preload: preload))
     |> assign(:conversations, [])}
  end

  @impl true
  def handle_info({_, {:participant_contact_set, %{id: participant_id} = participant}}, socket) do
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

    {:noreply,
     socket
     |> assign(:meeting, %{meeting | participants: participants})
     |> assign(:conversations, conversations)}
  end

  @impl true
  def handle_event("assign-to-conversation", %{"id" => conversation_id}, socket) do
    meeting = socket.assigns.meeting

    Meetings.update_meeting(meeting, %{conversation_id: conversation_id})
    |> case do
      {:ok, meeting} ->
        {:noreply, assign(socket, :meeting, meeting)}

      {:error, changeset} ->
        {:noreply,
         socket
         |> put_flash(:error, "Failed to assign meeting to conversation")
         |> push_patch(to: ~p"/meetings/#{meeting.id}")}
    end
  end

  def handle_event("remove-from-conversation", _, socket) do
    meeting = socket.assigns.meeting

    Meetings.update_meeting(meeting, %{conversation_id: nil})
    |> case do
      {:ok, meeting} ->
        {:noreply, assign(socket, :meeting, meeting)}

      {:error, changeset} ->
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
    |> Map.put(:account_id, socket.assigns.user_setting.selected_account.id)
    |> Conversations.create_conversation()
    |> case do
      {:ok, conversation} ->
        {:ok, meeting} = Meetings.update_meeting(meeting, %{conversation_id: conversation.id})

        {:noreply, socket |> assign(:meeting, meeting)}

      {:error, changeset} ->
        {:noreply,
         socket
         |> put_flash(:error, "Failed to create conversation for meeting")
         |> push_patch(to: ~p"/meetings/#{meeting.id}")}
    end
  end

  defp page_title(:show), do: "Show Meeting"
  defp page_title(:edit), do: "Edit Meeting"

  defp all_participants_assigned?(meeting),
    do: Enum.all?(meeting.participants, &(&1.contact_id != nil))
end
