defmodule DiscussitWeb.IndexLive.Components do
  alias Discussit.Contacts.Contact
  use DiscussitWeb, :html

  import DiscussitWeb.LiveSupport

  alias Discussit.Conversations.Conversation
  alias Discussit.UserSettings.UserSetting
  alias Discussit.PhoneNumbers.PhoneNumber

  attr(:conversation, Conversation, default: nil)
  attr(:zoom_level, :integer, default: 0)
  attr(:worker_busy?, :boolean, default: true)
  attr(:transcription_status, :map, default: %{})

  def participant_header(%{conversation: nil} = assigns), do: ~H""

  def participant_header(assigns) do
    ~H"""
    <div class="flex w-full bg-base-300 justify-between py-2 px-4 sticky top-0 z-10 mb-2">
      <div class="flex flex-row space-x-4 flex-wrap">
        <.participant_picker
          :for={participant <- @conversation.participants}
          participant={participant}
          class=""
          last={false}
        />
      </div>
      <div class="flex flex-row items-center space-x-4">
        <.transcribe
          conversation={@conversation}
          worker_busy?={@worker_busy?}
          transcription_status={@transcription_status}
        />
        <button class="btn btn-xs btn-secondary" phx-click="summarize" disabled={@worker_busy?}>
          Summarize
        </button>
        <.form for={%{}} as={:zoom_form} phx-change="zoom" class="w-24" id="zoom-form">
          <input
            type="range"
            min="0"
            max="3"
            value={@zoom_level}
            class="range"
            step="1"
            name="zoom"
            id="zoom-input"
            phx-debounce="500"
          />
        </.form>
      </div>
    </div>
    """
  end

  def transcribe(assigns) do
    ~H"""
    <div class="flex flex-col">
      <button
        class="btn btn-xs btn-secondary rounded-b-none"
        phx-click="transcribe_conversation_calls"
        phx-value-conversation-id={@conversation.id}
        disabled={@worker_busy?}
      >
        Transcribe
      </button>
      <div class="relative">
        <div class="overflow-hidden h-2 text-xs flex rounded rounded-t-none">
          <div
            style={"width: #{Map.get(@transcription_status, :done, 0)}%"}
            class="shadow-none flex flex-col text-center whitespace-nowrap text-white justify-center bg-success"
          >
          </div>
          <div
            style={"width: #{Map.get(@transcription_status, :in_progress, 0)}%"}
            class="shadow-none flex flex-col text-center whitespace-nowrap text-white justify-center bg-primary"
          >
          </div>
          <div
            style={"width: #{Map.get(@transcription_status, :warning, 0)}%"}
            class="shadow-none flex flex-col text-center whitespace-nowrap text-white justify-center bg-warning"
          >
          </div>
          <div
            style={"width: #{Map.get(@transcription_status, :error, 0)}%"}
            class="shadow-none flex flex-col text-center whitespace-nowrap text-white justify-center bg-error"
          >
          </div>
        </div>
      </div>
    </div>
    """
  end

  def participant_picker(%{participant: %{contact: %Contact{}}} = assigns),
    do: participant(assigns)

  def participant_picker(%{
        participant: %{phone_number: %{contacts: contacts} = phone_number} = participant,
        class: class,
        last: last
      }) do
    render_contact_picker(%{
      phone_number: phone_number,
      contacts: contacts,
      class: class,
      participant: participant,
      last: last
    })
  end

  def participant_search_dropdown(assigns) do
    ~H"""
    <input type="text" list="cars" />
    <datalist id="cars">
      <option>Volvo</option>
      <option>Saab</option>
      <option>Mercedes</option>
      <option>Audi</option>
    </datalist>
    """
  end

  def participant_or_picker(assigns), do: participant(assigns)

  def render_contact_picker(assigns) do
    ~H"""
    <div class="flex flex-row items-center gap-2">
      <.participant participant={@participant} class={@class} />
      <details class={["dropdown pr-0 mr-0", if(@last, do: "dropdown-end", else: "")]}>
        <summary tabindex="0" class="btn btn-xs" id={"participant-dropdown-toggle-#{@participant.id}"}>
          <.icon name="hero-chevron-down" class="w-3 h-3" />
        </summary>
        <ul tabindex="0" class="dropdown-content z-[0] menu p-2 bg-base-300 rounded-box w-52">
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
          <li>
            <.link href={
              ~p"/contacts/new?#{[phone_number: @participant.phone_number.value |> to_string()]}"
            }>
              New Contact
            </.link>
          </li>
        </ul>
      </details>
    </div>
    """
  end

  def participant(assigns) do
    ~H"""
    <.render_contact
      :if={is_struct(@participant.contact, Discussit.Contacts.Contact)}
      contact={@participant.contact}
      class={@class}
    />
    <%= if @participant.contact_id == nil && is_struct(@participant.phone_number, PhoneNumber) do %>
      <.render_contact
        :if={length(@participant.phone_number.contacts) == 1}
        contact={@participant.phone_number.contacts |> Enum.at(0)}
        class={["text-warning", @class]}
      />
      <.render_phone_number
        :if={length(@participant.phone_number.contacts) != 1}
        phone_number={@participant.phone_number}
        class={@class}
      />
    <% end %>
    <%= if @participant.contact_id == nil && @participant.phone_number_id == nil do %>
      <%= @participant.name %>
    <% end %>
    """
  end

  def render_contact(assigns) do
    ~H"""
    <span class={["whitespace-nowrap", @class]}>
      <%= @contact.first_name %> <%= @contact.last_name %>
    </span>
    """
  end

  def render_phone_number(assigns) do
    ~H"""
    <span class={["whitespace-nowrap", @class]}><%= @phone_number.value |> to_string() %></span>
    """
  end

  def render_date(%NaiveDateTime{} = date_time, %UserSetting{} = user_setting) do
    options = select_options(UserSetting, :timezone)
    timezone = Keyword.get(options, user_setting.timezone, "Etc/UTC")
    {:ok, local} = DateTime.from_naive(date_time, timezone)
    "#{local.month}/#{local.day} #{local.hour}:#{local.minute}"
  end

  def render_day(%NaiveDateTime{} = date_time, %UserSetting{} = user_setting) do
    options = select_options(UserSetting, :timezone)
    timezone = Keyword.get(options, user_setting.timezone, "Etc/UTC")
    DateTime.from_naive!(date_time, timezone) |> Date.to_string()
  end

  def render_week(%NaiveDateTime{} = date_time, %UserSetting{} = user_setting) do
    options = select_options(UserSetting, :timezone)
    timezone = Keyword.get(options, user_setting.timezone, "Etc/UTC")
    date = DateTime.from_naive!(date_time, timezone) |> Date.to_string()
    "Week of #{date}"
  end

  def render_month(%NaiveDateTime{} = date_time, %UserSetting{} = user_setting) do
    options = select_options(UserSetting, :timezone)
    timezone = Keyword.get(options, user_setting.timezone, "Etc/UTC")
    %{month: month} = DateTime.from_naive!(date_time, timezone)
    "#{Timex.month_name(month)}"
  end
end
