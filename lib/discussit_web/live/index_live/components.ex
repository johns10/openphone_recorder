defmodule DiscussitWeb.IndexLive.Components do
  use DiscussitWeb, :html
  alias Discussit.Conversations.Conversation

  attr(:conversation, Conversation, default: nil)

  def participant_header(%{conversation: nil} = assigns), do: ~H""

  def participant_header(assigns) do
    ~H"""
    <div class="flex w-full bg-base-300 justify-between py-2 px-4">
      <.participant_or_picker
        participant={Enum.at(@conversation.participants, 0)}
        class=""
        last={false}
      />
      <.participant_or_picker
        participant={Enum.at(@conversation.participants, 1)}
        class=""
        last={true}
      />
    </div>
    """
  end

  def participant_or_picker(%{
        participant: %{phone_number: %{contacts: contacts} = phone_number} = participant,
        class: class,
        last: last
      })
      when length(contacts) > 1,
      do:
        render_contact_picker(%{
          phone_number: phone_number,
          contacts: contacts,
          class: class,
          participant: participant,
          last: last
        })

  def participant_or_picker(assigns), do: participant(assigns)

  def render_contact_picker(assigns) do
    ~H"""
    <div class="flex flex-row items-center gap-2">
      <.participant participant={@participant} class={@class} />
      <div class={["dropdown pr-0 mr-0", if(@last, do: "dropdown-end", else: "")]}>
        <label tabindex="0">
          <span class="btn btn-xs" id={"participant-dropdown-toggle-#{@participant.id}"}>
            <.icon name="hero-chevron-down" class="w-3 h-3" />
          </span>
        </label>
        <ul tabindex="0" class="dropdown-content z-[1] menu p-2 bg-base-300 rounded-box w-52">
          <li :for={contact <- @contacts}>
            <.link
              phx-click="set-participant-contact"
              phx-value-participant-id={@participant.id}
              phx-value-contact-id={contact.id}
              id={"participant-contact-option-#{contact.id}"}
            >
              <%= contact.first_name %> <%= contact.last_name %>
            </.link>
          </li>
        </ul>
      </div>
    </div>
    """
  end

  def participant(assigns) do
    ~H"""
    <%= case {@participant.contact, length(@participant.phone_number.contacts)} do %>
      <% { nil, _} -> %>
        <.render_phone_number phone_number={@participant.phone_number} , class={@class} } />
      <% {_, 1} -> %>
        <.render_contact contact={@participant.phone_number.contacts |> Enum.at(0)} class={@class} />
      <% _ -> %>
        <.render_contact contact={@participant.contact} class={@class} />
    <% end %>
    """
  end

  def render_contact(assigns) do
    ~H"""
    <span class={@class}><%= @contact.first_name %> <%= @contact.last_name %></span>
    """
  end

  def render_phone_number(assigns) do
    ~H"""
    <span class={@class}><%= @phone_number.value |> to_string() %></span>
    """
  end
end
