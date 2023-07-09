defmodule Mix.Tasks.SetEventsAccountId do
  use Mix.Task
  alias OpenphoneRecorder.Events
  alias OpenphoneRecorder.Accounts

  def run([account_id]) do
    Application.ensure_all_started(:openphone_recorder)
    if !Accounts.get_account!(account_id), do: raise("Invalid account id")

    Events.list_events()
    |> Enum.each(fn event ->
      Events.update_event(event, %{account_id: account_id})
    end)
  end
end
