defmodule Discussit.ConversationWorker.Server do
  defstruct opts: [],
            conversation: nil,
            conversation_summarizers: []

  require Logger
  use GenServer
  alias Discussit.Conversations.Conversation
  alias Discussit.Accounts.Account
  alias Discussit.Accounts
  alias Discussit.ConversationWorker.Impl

  def init(%{
        conversation: %Conversation{id: id} = conversation,
        account: %Account{timezone: timezone} = account
      }) do
    Logger.debug("Starting conversation worker for conversation #{id}")
    openai_config = Accounts.cast_openai_config(account)

    broadcast_function = fn event, summary ->
      conversation
      |> Impl.name()
      |> Atom.to_string()
      |> DiscussitWeb.Endpoint.broadcast(event, summary)
    end

    state = %__MODULE__{
      conversation: conversation,
      opts: [
        timezone: Atom.to_string(timezone),
        openai_config: openai_config,
        broadcast_function: broadcast_function,
        account_id: account.id
      ]
    }

    {:ok, state}
  end

  def handle_cast(:busy, state) do
    Impl.broadcast_idle(state)
    {:noreply, state}
  end

  def handle_cast(:run_summarizers, %{conversation_summarizers: cs, opts: opts} = state) do
    [daily, weekly, monthly, _yearly] = cs
    Impl.broadcast_busy(state)
    Impl.create_daily_summaries(daily, opts)
    Impl.create_weekly_summaries(weekly, opts)
    Impl.create_monthly_summaries(monthly, opts)
    Impl.broadcast_idle(state)
    {:noreply, state}
  end

  def handle_cast(:get_conversation_summarizers, state) do
    [_daily, _weekly, _monthly, _yearly] = cs = Impl.ensure_conversation_summarizers_exist(state)
    {:noreply, %{state | conversation_summarizers: cs}}
  end
end
