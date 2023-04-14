defmodule OpenphoneRecorder.ContactPhoneNumbersFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `OpenphoneRecorder.ContactPhoneNumbers` context.
  """

  @doc """
  Generate a contact_phone_number.
  """
  def contact_phone_number_fixture(attrs \\ %{}) do
    {:ok, contact_phone_number} =
      attrs
      |> Enum.into(%{})
      |> OpenphoneRecorder.ContactPhoneNumbers.create_contact_phone_number()

    contact_phone_number
  end
end
