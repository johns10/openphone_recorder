defmodule Discussit.Contacts do
  @behaviour Bodyguard.Policy
  import Ecto.Query, warn: false
  alias Discussit.Repo
  alias Discussit.Contacts.Contact

  def authorize(action, user, %{account_id: account_id})
      when action in [:get_contact!, :delete_contact] do
    account_ids =
      Discussit.Accounts.list_accounts(filters: [user_id: user.id])
      |> Enum.map(& &1.id)

    if account_id in account_ids, do: :ok, else: :error
  end

  def authorize(action, _user, _contact)
      when action in [:get_contact!, :delete_contact],
      do: :error

  def list_contacts(opts \\ []) do
    filters = Keyword.get(opts, :filters, [])

    Contact
    |> filter_by_account_id(filters[:account_id])
    |> filter_by_phone_number_id(filters[:phone_number_id])
    |> Repo.all()
  end

  def get_contact!(id, opts \\ []) do
    preload = Keyword.get(opts, :preload, [])

    from(c in Contact, preload: ^preload)
    |> Repo.get!(id)
  end

  defp filter_by_account_id(query, nil), do: query

  defp filter_by_account_id(query, account_id) do
    query
    |> where([c], c.account_id == ^account_id)
  end

  defp filter_by_phone_number_id(query, nil), do: query

  defp filter_by_phone_number_id(query, phone_number_id) do
    query
    |> join(:left, [c], cpn in assoc(c, :contact_phone_numbers), as: :cpn)
    |> where([cpn: cpn], cpn.phone_number_id == ^phone_number_id)
  end

  def create_contact(attrs \\ %{}) do
    %Contact{}
    |> Contact.changeset(attrs)
    |> Repo.insert()
  end

  def upsert_contact(attrs \\ %{}) do
    %Contact{}
    |> Contact.changeset(attrs)
    |> Repo.insert()
    |> case do
      {:error, %{errors: [id: {"has already been taken", _}]} = changeset} ->
        changeset
        |> Ecto.Changeset.get_field(:id)
        |> get_contact!()
        |> update_contact(attrs)

      {:ok, _} = result ->
        result
    end
  end

  def update_contact(%Contact{} = contact, attrs) do
    contact
    |> Contact.changeset(attrs)
    |> Repo.update()
  end

  def delete_contact(%Contact{} = contact) do
    Repo.delete(contact)
  end

  def change_contact(%Contact{} = contact, attrs \\ %{}) do
    Contact.changeset(contact, attrs)
  end
end
