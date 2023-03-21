defmodule OpenphoneRecorder.PhoneNumbersFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `OpenphoneRecorder.PhoneNumbers` context.
  """

  @doc """
  Generate a phone_number.
  """
  def phone_number_fixture(attrs \\ %{}) do
    {:ok, phone_number} =
      attrs
      |> Enum.into(%{
        external_id: "some external_id",
        phone_number: "12566583336",
        source: :openphone
      })
      |> OpenphoneRecorder.PhoneNumbers.create_phone_number()

    phone_number
  end
end
