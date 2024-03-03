defmodule DiscussitWeb.IndexLive.Components do
  alias Oban.Job
  alias Discussit.Contacts.Contact
  use DiscussitWeb, :html

  import DiscussitWeb.LiveSupport

  alias Discussit.Conversations.Conversation
  alias Discussit.Users.User
  alias Discussit.PhoneNumbers.PhoneNumber
  alias Discussit.Summarizers.Summarizer
  alias Discussit.ConversationSummarizers.ConversationSummarizer

  attr(:conversation, Conversation, default: nil)

  def participant_header(%{conversation: nil} = assigns), do: ~H""

  def participant_header(assigns) do
    ~H"""
    <div class="flex flex-row space-x-4 flex-wrap">
      <.participant_picker
        :for={participant <- @conversation.participants}
        participant={participant}
        class=""
        last={false}
      />
    </div>
    """
  end

  def summarize_conversation_button(assigns) do
    ~H"""
    <button class="btn btn-xs btn-secondary" phx-click={paywall("summarize", @account)}>
      Summarize
    </button>
    """
  end

  def transcribe_conversation_button(assigns) do
    ~H"""
    <div class="flex flex-col">
      <button
        :if={@conversation}
        class="btn btn-xs btn-secondary rounded-b-none"
        phx-click={paywall("transcribe_conversation_calls", @account)}
        phx-value-conversation-id={@conversation.id}
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

  def transcribe_call_button(assigns) do
    ~H"""
    <.link
      id={"transcribe-call-#{@call.id}"}
      class={["btn btn-primary btn-xs transcribe-button"]}
      phx-click={paywall("transcribe", @account)}
      phx-value-call-id={@call.id}
    >
      Transcribe
    </.link>
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

  attr :summarizer, Summarizer, required: false
  attr :job, Job, default: nil

  def start_summarizer_button(%{summarizer: nil} = assigns), do: ~H""

  def start_summarizer_button(%{job: nil} = assigns),
    do: enabled_play_button(assigns)

  def start_summarizer_button(%{job: %{state: state}} = assigns)
      when state in ["completed"],
      do: done_play_button(assigns)

  def start_summarizer_button(%{job: %{state: state}} = assigns)
      when state in ["executing", "retryable"],
      do: running_summarizer_button(assigns)

  def start_summarizer_button(%{job: %{state: state}} = assigns)
      when state in ["scheduled", "available"],
      do: disabled_play_button(assigns)

  def start_summarizer_button(%{job: %{state: state}} = assigns)
      when state in ["discarded", "cancelled"],
      do: warn_play_button(assigns)

  def start_summarizer_button(assigns),
    do: ~H""

  def enabled_play_button(assigns) do
    ~H"""
    <.link
      id="start-summarizer"
      phx-click="summarize"
      phx-value-summarizer-id={@summarizer.id}
      class="btn btn-xs btn-secondary join-item"
    >
      <.icon name="hero-play" class="w-4 h-4" />
    </.link>
    """
  end

  def disabled_play_button(assigns) do
    ~H"""
    <.link
      id="start-summarizer"
      phx-click="summarize"
      phx-value-summarizer-id={@summarizer.id}
      class="btn btn-xs btn-secondary join-item btn-disabled"
    >
      <.icon name="hero-play" class="w-4 h-4" />
    </.link>
    """
  end

  def warn_play_button(assigns) do
    ~H"""
    <.link
      id="start-summarizer"
      phx-click="reset-summarizer"
      phx-value-summarizer-id={@summarizer.id}
      class="btn btn-xs btn-secondary join-item"
    >
      <.icon name="hero-exclamation-triangle" class="w-4 h-4" />
    </.link>
    """
  end

  def done_play_button(assigns) do
    ~H"""
    <.link
      id="start-summarizer"
      phx-click="reset-summarizer"
      phx-value-summarizer-id={@summarizer.id}
      class="btn btn-xs btn-secondary join-item"
    >
      <.icon name="hero-check" class="w-4 h-4" />
    </.link>
    """
  end

  def disabled_warn_button(assigns) do
    ~H"""
    <.link
      id="start-summarizer"
      phx-click="summarize"
      phx-value-summarizer-id={@summarizer.id}
      class="btn btn-xs btn-secondary join-item btn-disabled animate-pulse"
    >
      <.icon name="exclamation-circle" class="w-4 h-4" />
    </.link>
    """
  end

  def running_summarizer_button(assigns) do
    ~H"""
    <.link id="start-summarizer" class="btn btn-xs btn-secondary join-item btn-disabled">
      <.icon name="hero-arrow-path" class="w-4 h-4 animate-spin" />
    </.link>
    """
  end

  def cancel_summarizer_button(%{job: nil} = assigns), do: ~H""

  def cancel_summarizer_button(%{job: %{state: state}} = assigns)
      when state in ["executing", "scheduled", "available", "retryable"] do
    ~H"""
    <.link
      id="cancel-summarizer"
      phx-click="cancel-summarizer"
      phx-value-id={@conversation_summarizer.id}
      class="btn btn-xs btn-secondary join-item"
    >
      <.icon name="hero-x-mark" class="w-4 h-4" />
    </.link>
    """
  end

  def cancel_summarizer_button(assigns), do: ~H""

  attr :conversation_summarizer, ConversationSummarizer, default: nil

  def view_summarizer_button(%{conversation_summarizer: nil} = assigns), do: ~H""

  def view_summarizer_button(%{conversation_summarizer: %{id: nil}} = assigns) do
    ~H"""
    <.link class="btn btn-xs btn-secondary join-item btn-disabled">
      <.icon name="hero-magnifying-glass" class="w-4 h-4" />
    </.link>
    """
  end

  def view_summarizer_button(assigns) do
    ~H"""
    <.link
      href={~p"/conversation_summarizers/#{@conversation_summarizer}"}
      class="btn btn-xs btn-secondary join-item"
    >
      <.icon name="hero-magnifying-glass" class="w-4 h-4" />
    </.link>
    """
  end

  def render_date(%NaiveDateTime{} = date_time, %User{} = user) do
    options = select_options(User, :timezone)
    timezone = Keyword.get(options, user.timezone, "Etc/UTC")
    {:ok, local} = DateTime.from_naive(date_time, timezone)
    "#{local.month}/#{local.day} #{local.hour}:#{local.minute}"
  end

  def render_day(%NaiveDateTime{} = date_time, %User{} = user) do
    options = select_options(User, :timezone)
    timezone = Keyword.get(options, user.timezone, "Etc/UTC")
    DateTime.from_naive!(date_time, timezone) |> Date.to_string()
  end

  def render_week(%NaiveDateTime{} = date_time, %User{} = user) do
    options = select_options(User, :timezone)
    timezone = Keyword.get(options, user.timezone, "Etc/UTC")
    date = DateTime.from_naive!(date_time, timezone) |> Date.to_string()
    "Week of #{date}"
  end

  def render_month(%NaiveDateTime{} = date_time, %User{} = user) do
    options = select_options(User, :timezone)
    timezone = Keyword.get(options, user.timezone, "Etc/UTC")
    %{month: month} = DateTime.from_naive!(date_time, timezone)
    "#{Timex.month_name(month)}"
  end
end
