defmodule OpenphoneRecorderWeb.IndexLive.Components do
  use OpenphoneRecorderWeb, :html
  alias OpenphoneRecorder.Conversations.Conversation


  attr :conversation, Conversation, default: nil

  def conversation(assigns) do
    ~H"""
    <a href={~p"/conversation/#{@conversation}"} class="w-full px-4 py-2 hover:bg-base-200">
      <.participants participants={@conversation.participants} />
    </a>
    """
  end

  def participants(%{participants: [primary | additional]}) do
    %{primary_participant: primary, additional_participants: additional}
    |> render_participants()
  end

  def render_participants(assigns) do
    ~H"""
    <div class="flex flex-col">
      <.participant participant={@primary_participant} class="font-bold" />
      <div class="flex flex-row">
        <%= for participant <- @additional_participants do %>
          <.participant participant={participant} class="font-light" />
        <% end %>
      </div>
    </div>
    """
  end

  def participant(%{participant: %{phone_number: %{contacts: [contact]}}, class: class}),
    do: render_contact(%{contact: contact, class: class})

  def participant(%{participant: %{phone_number: phone_number}, class: class}),
    do: render_phone_number(%{phone_number: phone_number, class: class})

  def render_contact(assigns) do
    ~H"""
    <span class={@class}><%= @contact.first_name %> <%= @contact.last_name %></span>
    """
  end

  def render_phone_number(assigns) do
    ~H"""
    <span class={@class}><%= @phone_number.phone_number |> to_string() %></span>
    """
  end
end
