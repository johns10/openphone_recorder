defmodule OpenphoneRecorder.ContactPhoneNumbers do
  @moduledoc """
  The ContactPhoneNumbers context.
  """

  import Ecto.Query, warn: false
  alias OpenphoneRecorder.Repo

  alias OpenphoneRecorder.ContactPhoneNumbers.ContactPhoneNumber

  def list_contact_phone_numbers do
    Repo.all(ContactPhoneNumber)
  end

  def get_contact_phone_number!(id), do: Repo.get!(ContactPhoneNumber, id)

  def create_contact_phone_number(attrs \\ %{}) do
    %ContactPhoneNumber{}
    |> ContactPhoneNumber.changeset(attrs)
    |> Repo.insert()
  end

  def get_or_insert_all_contact_phone_number(attrs) do
    attrs
    |> Enum.reduce({:ok, %{contact_phone_numbers: [], changesets: []}}, fn attrs, {status, acc} ->
      case get_or_insert_contact_phone_number(attrs) do
        {:ok, contact_phone_number} ->
          {status,
           %{acc | contact_phone_numbers: [contact_phone_number | acc.contact_phone_numbers]}}

        {:error, changeset} ->
          {:error, %{acc | changesets: [changeset | acc.changesets]}}
      end
    end)
  end

  def get_or_insert_contact_phone_number(attrs \\ %{}) do
    %ContactPhoneNumber{}
    |> ContactPhoneNumber.changeset(attrs)
    |> Repo.insert()
    |> case do
      {:error, %{errors: [contact_id: _], changes: changes}} ->
        {:ok, Repo.get_by(ContactPhoneNumber, changes)}

      success ->
        success
    end
  end

  def update_contact_phone_number(%ContactPhoneNumber{} = contact_phone_number, attrs) do
    contact_phone_number
    |> ContactPhoneNumber.changeset(attrs)
    |> Repo.update()
  end

  def delete_contact_phone_number(%ContactPhoneNumber{} = contact_phone_number) do
    Repo.delete(contact_phone_number)
  end

  def change_contact_phone_number(%ContactPhoneNumber{} = contact_phone_number, attrs \\ %{}) do
    ContactPhoneNumber.changeset(contact_phone_number, attrs)
  end
end
