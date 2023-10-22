defmodule DiscussitWeb.MeetingLive.ParticipantFinder do
  alias Discussit.Participants
  use DiscussitWeb, :live_component

  alias Discussit.Contacts
  import DiscussitWeb.IndexLive.Components

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex space-x-2">
      <.participant participant={@participant} class="" />
      <div
        class="btn btn-xs"
        id={"find-participant-#{@participant.id}"}
        phx-click={
          JS.push("hydrate-contacts")
          |> JS.toggle(to: "#find-participant-menu-#{@participant.id}")
        }
        phx-target={@myself}
      >
        <.icon name="hero-chevron-down" class="w-3 h-3" />
      </div>
      <ul
        tabindex="0"
        class="dropdown-content menu bg-base-300 rounded-box w-52 absolute z-[50]"
        id={"find-participant-menu-#{@participant.id}"}
        style="display: none;"
      >
        <li>
          <.form
            for={@form}
            id={"contact-search-#{@participant.id}"}
            class="p-0"
            phx-change="search"
            phx-target={@myself}
          >
            <input
              type="text"
              class="input w-full m-0 rounded-b-none bg-base-200"
              name="search"
              placeholder="Contact Name"
            />
          </.form>
        </li>
        <li :for={contact <- @contacts}>
          <.link
            id={"participant-#{@participant.id}-contact-#{contact.id}"}
            phx-click={
              JS.push("set-participant-contact")
              |> JS.toggle(to: "#find-participant-menu-#{@participant.id}")
            }
            phx-value-participant-id={@participant.id}
            phx-value-contact-id={contact.id}
            phx-value-meeting-id={@meeting.id}
            phx-target={@myself}
          >
            <%= contact.first_name %> <%= contact.last_name %>
          </.link>
        </li>
        <li>
          <.link href={~p"/contacts/new"}>New Contact</.link>
        </li>
      </ul>
    </div>
    """
  end

  @impl true
  def update(%{participant: _participant, account_id: account_id} = assigns, socket) do
    contacts = Contacts.list_contacts(limit: 5, filters: [account_id: account_id])

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:contacts, contacts)
     |> assign(:form, to_form(%{"search" => ""}))}
  end

  @impl true
  def handle_event("search", %{"search" => text}, socket) do
    contacts = Contacts.list_contacts(filters: [search: text], limit: 5)
    {:noreply, assign(socket, :contacts, contacts)}
  end

  def handle_event("hydrate-contacts", _, socket) do
    {:noreply, socket}
  end

  def handle_event(
        "set-participant-contact",
        %{"contact-id" => contact_id, "meeting-id" => meeting_id},
        socket
      ) do
    {:ok, participant} =
      Participants.update_participant(socket.assigns.participant, %{contact_id: contact_id})

    contact = Contacts.get_contact!(contact_id)
    participant = Map.put(participant, :contact, contact)

    send_update(socket.assigns.notify, %{
      id: meeting_id,
      event: :participant_contact_set,
      participant: participant
    })

    {:noreply, socket |> assign(:participant, participant)}
  end
end
