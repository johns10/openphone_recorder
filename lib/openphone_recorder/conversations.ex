defmodule OpenphoneRecorder.Conversations do
  import Ecto.Query, warn: false
  alias OpenphoneRecorder.Repo

  alias OpenphoneRecorder.Conversations.Conversation

  def list_conversations(opts \\ []) do
    preloads = Keyword.get(opts, :preloads, nil)

    Conversation
    |> maybe_preload(preloads)
    |> Repo.all()
  end

  def list_conversation_summary do
    from(c in Conversation)
    |> join(:left, [c], p in assoc(c, :participants), as: :participants)
    |> join(:left, [participants: p], pn in assoc(p, :phone_number), as: :phone_number)
    |> join(:left, [phone_number: pn], c in assoc(pn, :contact_phone_numbers), as: :contact_phone_numbers)
    |> join(:left, [contact_phone_numbers: cpn], c in assoc(cpn, :contact), as: :contacts)
    |> order_by(
      [contacts: c, contact_phone_numbers: cpn],
      [
        asc: cpn.contact_id,
        desc: fragment("CASE 'relationship' when 'primary' then 1 when 'internal' then 2 when 'external' then 3 end")
      ]
    )
    |> preload(
      [participants: p, phone_number: pn, contacts: c],
      participants: {p, phone_number: {pn, contacts: c}}
    )
    |> Repo.all()
  end

  def get_conversation!(id), do: Repo.get!(Conversation, id)

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
