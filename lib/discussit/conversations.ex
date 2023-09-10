defmodule Discussit.Conversations do
  @behaviour Bodyguard.Policy
  import Ecto.Query, warn: false
  alias Discussit.Repo
  alias Discussit.Participants
  alias Discussit.Conversations.Conversation
  alias Discussit.Participants.Participant
  alias Discussit.Statements.Statement

  def authorize(:get_conversation!, user, %{account_id: account_id}) do
    account_ids =
      Discussit.Accounts.list_accounts(filters: [user_id: user.id])
      |> Enum.map(& &1.id)

    if account_id in account_ids, do: :ok, else: :error
  end

  def authorize(:get_conversation!, _user, _conversation), do: :error

  def list_conversations(opts \\ []) do
    filters = Keyword.get(opts, :filters, [])
    preloads = Keyword.get(opts, :preloads, nil)
    order_bys = Keyword.get(opts, :order_bys, [])

    Conversation
    |> maybe_preload(preloads)
    |> filter_by_exact_contact_ids(filters[:exact_contact_ids])
    |> filter_by_account_id(filters[:account_id])
    |> order_by_last_statement_occured_at(order_bys[:last_statement_occurred_at])
    |> Repo.all()
  end

  def conversation_summary(query, account_id) do
    participants_query =
      from(p in Participant)
      |> join(:left, [p], pn in assoc(p, :phone_number), as: :phone_number)
      |> join(:left, [p], c in assoc(p, :contact), as: :contact)
      |> join(:left, [phone_number: pn], c in assoc(pn, :contact_phone_numbers),
        as: :contact_phone_numbers
      )
      |> join(:left, [phone_number: pn], c in assoc(pn, :contacts), as: :contacts)
      |> preload(
        [phone_number: pn, contacts: cs, contact: c],
        phone_number: {pn, contacts: cs},
        contact: c
      )

    query
    |> where([c], c.account_id == ^account_id)
    |> order_by_last_statement_occured_at(:desc_nulls_last)
    |> preload([c], participants: ^participants_query)
  end

  def list_conversation_summary(account_id, opts \\ []) do
    offset = Keyword.get(opts, :offset, 0)
    limit = Keyword.get(opts, :limit, 20)

    from(c in Conversation)
    |> offset(^offset)
    |> limit(^limit)
    |> conversation_summary(account_id)
    |> Repo.all()
  end

  def get_conversation_summary!(id, account_id) do
    Conversation
    |> conversation_summary(account_id)
    |> Repo.get!(id)
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

  defp filter_by_exact_contact_ids(query, nil), do: query
  defp filter_by_exact_contact_ids(query, []), do: query

  defp filter_by_exact_contact_ids(query, contact_ids) do
    ids_count = Enum.count(contact_ids)

    query
    |> join(:inner, [c], p in assoc(c, :participants), as: :participants)
    |> group_by([c, participants: p], c.id)
    |> having([c, participants: p], count(p.contact_id, :distinct) == ^ids_count)
  end

  defp order_by_last_statement_occured_at(query, nil), do: query

  defp order_by_last_statement_occured_at(query, order) do
    last_statement =
      from s in Statement,
        group_by: s.conversation_id,
        select: %{conversation_id: s.conversation_id, occurred_at: max(s.occurred_at)}

    query
    |> join(:left, [c], last in subquery(last_statement),
      on: last.conversation_id == c.id,
      as: :statement
    )
    |> order_by([statement: s], [{^order, s.occurred_at}])
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

  def update_conversation(%Conversation{} = conversation, attrs) do
    conversation
    |> Conversation.changeset(attrs)
    |> Repo.update()
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
