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

    contact_ids = Enum.map(participants, & &1.contact_id) |> IO.inspect()

    conversations =
      Conversations.list_conversations(
        filters: [exact_contact_ids: contact_ids],
        preloads: [participants: :contact]
      )

    conversations |> Enum.count() |> IO.inspect()

    {:noreply,
     socket
     |> assign(:meeting, %{meeting | participants: participants})
     |> assign(:conversations, conversations)}
  end

  @impl true
  def handle_event("assign-to-conversation", %{"id" => conversation_id}, socket) do
    Meetings.update_meeting(socket.assigns.meeting, %{conversation_id: conversation_id})
    |> case do
      {:ok, meeting} ->
        {:noreply, assign(socket, :meeting, meeting)}
    end
  end

  defp page_title(:show), do: "Show Meeting"
  defp page_title(:edit), do: "Edit Meeting"

  defp all_participants_assigned?(meeting),
    do: Enum.all?(meeting.participants, &(&1.contact_id != nil))
end
