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
        external_id: "some external_id",
        first_name: "some updated first_name",
        last_name: "some updated last_name",
        source: :openphone
      })
      |> OpenphoneRecorder.Contacts.create_contact()

    contact
  end
end
