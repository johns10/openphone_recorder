defmodule Mix.Tasks.SetAccountId do
  use Mix.Task
  alias Discussit.Events
  alias Discussit.Contacts
  alias Discussit.Accounts
  alias Discussit.Conversations

  def run([account_id]) do
    Application.ensure_all_started(:discussit)
    if !Accounts.get_account!(account_id), do: raise("Invalid account id")

    Events.list_events()
    |> Enum.each(fn event ->
      Events.update_event(event, %{account_id: account_id})
    end)

    Contacts.list_contacts()
    |> Enum.each(fn contact ->
      Contacts.update_contact(contact, %{account_id: account_id})
    end)

    Conversations.list_conversations()
    |> Enum.each(fn conversation ->
      Conversations.update_conversation(conversation, %{account_id: account_id})
    end)
  end
end
