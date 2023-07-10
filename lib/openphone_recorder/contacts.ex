defmodule OpenphoneRecorder.Contacts do
  @behaviour Bodyguard.Policy
  import Ecto.Query, warn: false
  alias OpenphoneRecorder.Repo
  alias OpenphoneRecorder.Contacts.Contact

  def authorize(:get_contact!, user, %{account_id: account_id}) do
    account_ids =
      OpenphoneRecorder.Accounts.list_accounts(filters: [user_id: user.id])
      |> Enum.map(& &1.id)

    if account_id in account_ids, do: :ok, else: :error
  end

  def authorize(:get_contact!, _user, _contact), do: :error

  def list_contacts(opts \\ []) do
    filters = Keyword.get(opts, :filters, [])

    Contact
    |> filter_by_account_id(filters[:account_id])
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
