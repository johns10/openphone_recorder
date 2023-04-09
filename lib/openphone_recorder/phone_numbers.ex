defmodule OpenphoneRecorder.PhoneNumbers do
  import Ecto.Query, warn: false
  alias OpenphoneRecorder.Repo

  alias OpenphoneRecorder.PhoneNumbers.PhoneNumber

  def list_phone_numbers do
    Repo.all(PhoneNumber)
  end

  def get_phone_number!(id), do: Repo.get!(PhoneNumber, id)

  def create_phone_number(attrs \\ %{}) do
    %PhoneNumber{}
    |> PhoneNumber.changeset(attrs)
    |> Repo.insert()
  end

  def upsert_all_phone_numbers(attrs) do
    attrs
    |> Enum.reduce({:ok, %{phone_numbers: [], changesets: []}}, fn attrs, {status, acc} ->
      case upsert_phone_number(attrs) do
        {:ok, phone_number} ->
          {status, %{acc | phone_numbers: [phone_number | acc.phone_numbers]}}

        {:error, changeset} ->
          {:error, %{acc | changesets: [changeset | acc.changesets]}}
      end
    end)
  end

  def upsert_phone_number(attrs \\ %{}) do
    changeset =
      %PhoneNumber{}
      |> PhoneNumber.changeset(attrs)

    changeset
    |> Repo.insert()
    |> case do
      {:error, %{errors: [id: {"has already been taken", _}]}} ->
        changeset
        |> Ecto.Changeset.get_field(:id)
        |> get_phone_number!()
        |> case do
          %{external_id: nil} = phone_number ->
            attrs = %{external_id: Ecto.Changeset.get_change(changeset, :external_id)}
            update_phone_number(phone_number, attrs)

          phone_number ->
            {:ok, phone_number}
        end

      success ->
        success
    end
  end

  def update_phone_number(%PhoneNumber{} = phone_number, attrs) do
    phone_number
    |> PhoneNumber.changeset(attrs)
    |> Repo.update()
  end

  def delete_phone_number(%PhoneNumber{} = phone_number) do
    Repo.delete(phone_number)
  end

  def change_phone_number(%PhoneNumber{} = phone_number, attrs \\ %{}) do
    PhoneNumber.changeset(phone_number, attrs)
  end
end
