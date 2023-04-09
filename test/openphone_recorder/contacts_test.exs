defmodule OpenphoneRecorder.ContactsTest do
  use OpenphoneRecorder.DataCase

  alias OpenphoneRecorder.Contacts

  describe "contacts" do
    alias OpenphoneRecorder.Contacts.Contact

    import OpenphoneRecorder.ContactsFixtures

    @invalid_attrs %{external_id: nil, full_name: nil, source: nil}

    test "list_contacts/0 returns all contacts" do
      contact = contact_fixture()
      assert Contacts.list_contacts() == [contact]
    end

    test "get_contact!/1 returns the contact with given id" do
      contact = contact_fixture()
      assert Contacts.get_contact!(contact.id) == contact
    end

    test "create_contact/1 with valid data creates a contact" do
      valid_attrs = %{external_id: "some external_id", full_name: "some full_name", source: :openphone}

      assert {:ok, %Contact{} = contact} = Contacts.create_contact(valid_attrs)
      assert contact.external_id == "some external_id"
      assert contact.full_name == "some full_name"
      assert contact.source == :openphone
    end

    test "create_contact/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Contacts.create_contact(@invalid_attrs)
    end

    test "update_contact/2 with valid data updates the contact" do
      contact = contact_fixture()
      update_attrs = %{external_id: "some updated external_id", full_name: "some updated full_name", source: :openphone}

      assert {:ok, %Contact{} = contact} = Contacts.update_contact(contact, update_attrs)
      assert contact.external_id == "some updated external_id"
      assert contact.full_name == "some updated full_name"
      assert contact.source == :openphone
    end

    test "update_contact/2 with invalid data returns error changeset" do
      contact = contact_fixture()
      assert {:error, %Ecto.Changeset{}} = Contacts.update_contact(contact, @invalid_attrs)
      assert contact == Contacts.get_contact!(contact.id)
    end

    test "delete_contact/1 deletes the contact" do
      contact = contact_fixture()
      assert {:ok, %Contact{}} = Contacts.delete_contact(contact)
      assert_raise Ecto.NoResultsError, fn -> Contacts.get_contact!(contact.id) end
    end

    test "change_contact/1 returns a contact changeset" do
      contact = contact_fixture()
      assert %Ecto.Changeset{} = Contacts.change_contact(contact)
    end
  end
end
