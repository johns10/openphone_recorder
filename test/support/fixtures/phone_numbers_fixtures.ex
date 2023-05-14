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
        external_id: Ecto.UUID.generate(),
        phone_number: "1256" <> Faker.Phone.EnUs.exchange_code() <> Faker.Phone.EnUs.subscriber_number() |> IO.inspect(),
        source: :openphone
      })
      |> OpenphoneRecorder.PhoneNumbers.create_phone_number()

    phone_number
  end
end
