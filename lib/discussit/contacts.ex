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
    preloads = Keyword.get(opts, :preloads, [])

    Contact
    |> preload(^preloads)
    |> filter_by_account_id(filters[:account_id])
    |> filter_by_phone_number_id(filters[:phone_number_id])
    |> Repo.all()
  end

  def get_contact!(id, opts \\ []) do
    preloads = Keyword.get(opts, :preloads, [])

    from(c in Contact)
    |> preload(^preloads)
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

  def update_nested_contact(%Contact{} = contact, attrs) do
    contact
    |> Contact.changeset(attrs)
    |> traverse()
    |> Repo.update()
  end

  def create_nested_contact(attrs) do
    %Contact{}
    |> Contact.changeset(attrs)
    |> traverse()
    |> Repo.insert()
  end

  def traverse(%{changes: %{contact_phone_numbers: contact_phone_numbers}} = changeset) do
    contact_phone_numbers =
      contact_phone_numbers
      |> Enum.map(fn
        %{changes: %{phone_number: %{changes: %{id: id}}}} = changeset ->
          case Discussit.PhoneNumbers.get_phone_number(id) do
            nil ->
              changeset

            %Discussit.PhoneNumbers.PhoneNumber{id: id} ->
              changeset
              |> Ecto.Changeset.delete_change(:phone_number)
              |> Ecto.Changeset.put_change(:phone_number_id, id)
          end

        %{changes: %{phone_number: %{changes: %{value: value}}}} = changeset ->
          id = Discussit.PhoneNumbers.PhoneNumber.id(value)

          case Discussit.PhoneNumbers.get_phone_number(id) do
            nil ->
              {:ok, phone_number} =
                Discussit.PhoneNumbers.create_phone_number(%{value: value, source: :user})

              changeset
              |> Ecto.Changeset.delete_change(:phone_number)
              |> Ecto.Changeset.put_change(:phone_number_id, phone_number.id)

            %Discussit.PhoneNumbers.PhoneNumber{id: id} ->
              changeset
              |> Ecto.Changeset.delete_change(:phone_number)
              |> Ecto.Changeset.put_change(:phone_number_id, id)
          end

        changeset ->
          changeset
      end)

    Ecto.Changeset.put_change(changeset, :contact_phone_numbers, contact_phone_numbers)
  end

  def traverse(changeset), do: changeset

  def delete_contact(%Contact{} = contact) do
    Repo.delete(contact)
  end

  def change_contact(%Contact{} = contact, attrs \\ %{}) do
    Contact.changeset(contact, attrs)
  end
end
