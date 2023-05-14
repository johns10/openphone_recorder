defmodule OpenphoneRecorder.ContactsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `OpenphoneRecorder.Contacts` context.
  """

  @doc """
  Generate a contact.
  """
  def contact_fixture(attrs \\ %{}) do
    {:ok, contact} =
      attrs
      |> Enum.into(%{
        external_id: Ecto.UUID.generate(),
        first_name: Faker.Person.En.first_name(),
        last_name: Faker.Person.En.last_name(),
        source: :openphone
      })
      |> OpenphoneRecorder.Contacts.create_contact()

    contact
  end
end
