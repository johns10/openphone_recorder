defmodule Discussit.ContactsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Discussit.Contacts` context.
  """

  @doc """
  Generate a contact.
  """
  def contact_fixture(attrs \\ %{}) do
    {:ok, contact} =
      attrs
      |> Enum.into(%{
        account_id: Discussit.AccountsFixtures.account_fixture().id,
        external_id: Ecto.UUID.generate(),
        first_name: Faker.Person.En.first_name(),
        last_name: Faker.Person.En.last_name(),
        source: :openphone
      })
      |> Discussit.Contacts.create_contact()

    contact
  end
end
