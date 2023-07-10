defmodule OpenphoneRecorder.Conversations do
  @behaviour Bodyguard.Policy
  import Ecto.Query, warn: false
  alias OpenphoneRecorder.Repo
  alias OpenphoneRecorder.Conversations.Conversation

  def authorize(:get_conversation!, user, %{account_id: account_id}) do
    account_ids =
      OpenphoneRecorder.Accounts.list_accounts(filters: [user_id: user.id])
      |> Enum.map(& &1.id)

    if account_id in account_ids, do: :ok, else: :error
  end

  def authorize(:get_conversation!, _user, _conversation), do: :error

  def list_conversations(opts \\ []) do
    filters = Keyword.get(opts, :filters, [])
    preloads = Keyword.get(opts, :preloads, nil)

    Conversation
    |> maybe_preload(preloads)
    |> filter_by_account_id(filters[:account_id])
    |> Repo.all()
  end

  def list_conversation_summary do
    from(c in Conversation)
    |> join(:left, [c], p in assoc(c, :participants), as: :participants)
    |> join(:left, [participants: p], pn in assoc(p, :phone_number), as: :phone_number)
    |> join(:left, [phone_number: pn], c in assoc(pn, :contact_phone_numbers),
      as: :contact_phone_numbers
    )
    |> join(:left, [phone_number: pn], c in assoc(pn, :contact), as: :contact)
    |> order_by([phone_number: pn, contact: contact],
      asc: contact.id,
      desc:
        fragment(
          "CASE 'relationship' when 'primary' then 1 when 'internal' then 2 when 'external' then 3 end"
        )
    )
    |> preload(
      [participants: p, phone_number: pn, contact: c],
      participants: {p, phone_number: {pn, contact: c}}
    )
    |> Repo.all()
  end

  def get_conversation!(id, opts \\ []) do
    preloads = Keyword.get(opts, :preloads, nil)

    Conversation
    |> maybe_preload(preloads)
    |> Repo.get!(id)
  end

  defp filter_by_account_id(query, nil), do: query

  defp filter_by_account_id(query, account_id) do
    query
    |> where([c], c.account_id == ^account_id)
  end

  def create_conversation(attrs \\ %{}) do
    %Conversation{}
    |> Conversation.changeset(attrs)
    |> Repo.insert()
  end

  def upsert_conversation(attrs \\ %{}) do
    changeset =
      %Conversation{}
      |> Conversation.changeset(attrs)

    changeset
    |> Repo.insert()
    |> case do
      {:error, %{errors: [id: {"has already been taken", _}]}} ->
        conversation =
          changeset
          |> Ecto.Changeset.get_field(:id)
          |> get_conversation!()

        {:ok, conversation}

      success ->
        success
    end
  end

  def delete_conversation(%Conversation{} = conversation) do
    Repo.delete(conversation)
  end

  def change_conversation(%Conversation{} = conversation, attrs \\ %{}) do
    Conversation.changeset(conversation, attrs)
  end

  defp maybe_preload(query, nil), do: query

  defp maybe_preload(query, preloads) do
    query
    |> preload(^preloads)
  end
end
