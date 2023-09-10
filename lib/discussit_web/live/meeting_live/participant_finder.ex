defmodule DiscussitWeb.MeetingLive.ParticipantFinder do
  alias Discussit.Participants
  use DiscussitWeb, :live_component

  alias Discussit.Contacts
  import DiscussitWeb.IndexLive.Components

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.participant participant={@participant} class="" />
      <details class={["dropdown pr-0 mr-0"]}>
        <summary
          tabindex="0"
          class="btn btn-xs"
          id={"find-participant-#{@participant.id}"}
          phx-click="hydrate-contacts"
          phx-value-account-id={@account_id}
          phx-target={@myself}
        >
          <.icon name="hero-chevron-down" class="w-3 h-3" />
        </summary>
        <ul tabindex="0" class="dropdown-content z-[0] menu p-2 bg-base-300 rounded-box w-52">
          <li>
            <.form
              for={%{}}
              id={"contact-search-#{@participant.id}"}
              phx-change="search"
              phx-target={@myself}
            >
              <input type="text" class="input" field={:search} />
            </.form>
          </li>
          <li :for={contact <- @contacts}>
            <.link
              id={"participant-contact-#{contact.id}"}
              phx-click="set-participant-contact"
              phx-value-participant-id={@participant.id}
              phx-value-contact-id={contact.id}
              phx-target={@myself}
            >
              <%= contact.first_name %> <%= contact.last_name %>
            </.link>
          </li>
          <li>
            <.link href={~p"/contacts/new"}>New Contact</.link>
          </li>
        </ul>
      </details>
    </div>
    """
  end

  @impl true
  def update(%{participant: _participant} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign(:contacts, [])}
  end

  @impl true
  def handle_event("search", %{"search" => text}, socket) do
    IO.puts("search")
    contacts = Contacts.list_contacts(filters: [search: text], limit: 5)

    {:noreply, assign(socket, :contacts, contacts)}
  end

  def handle_event("hydrate-contacts", %{"account-id" => account_id}, socket) do
    contacts = Contacts.list_contacts(limit: 5, filters: [account_id: account_id])
    {:noreply, assign(socket, :contacts, contacts)}
  end

  def handle_event("set-participant-contact", %{"contact-id" => contact_id}, socket) do
    {:ok, participant} =
      Participants.update_participant(socket.assigns.participant, %{contact_id: contact_id})

    contact = Contacts.get_contact!(contact_id)
    participant = Map.put(participant, :contact, contact)
    {:noreply, socket |> assign(:participant, participant)}
  end
end
