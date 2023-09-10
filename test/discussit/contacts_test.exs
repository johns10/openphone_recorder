defmodule Discussit.ContactsTest do
  use Discussit.DataCase

  alias Discussit.Contacts

  describe "contacts" do
    alias Discussit.Contacts.Contact

    import Discussit.ContactsFixtures

    @invalid_attrs %{external_id: nil, first_name: nil, source: nil}

    test "list_contacts/0 returns all contacts" do
      contact = contact_fixture()
      assert Contacts.list_contacts() == [contact]
    end

    test "list_contacts/1 with search returns the right contacts" do
      contact = contact_fixture()
      other_contact = contact_fixture()
      assert Contacts.list_contacts(filters: [search: contact.first_name]) == [contact]
    end

    test "get_contact!/1 returns the contact with given id" do
      contact = contact_fixture()
      assert Contacts.get_contact!(contact.id) == contact
    end

    test "create_contact/1 with valid data creates a contact" do
      valid_attrs = %{
        account_id: Discussit.AccountsFixtures.account_fixture().id,
        external_id: "some external_id",
        first_name: "some first_name",
        last_name: "some last_name",
        source: :openphone
      }

      assert {:ok, %Contact{} = contact} = Contacts.create_contact(valid_attrs)
      assert contact.external_id == "some external_id"
      assert contact.first_name == "some first_name"
      assert contact.last_name == "some last_name"
      assert contact.source == :openphone
    end

    test "create_contact/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Contacts.create_contact(@invalid_attrs)
    end

    test "upsert_contact/2 doesn't overwrite the record" do
      create_attrs = %{
        account_id: Discussit.AccountsFixtures.account_fixture().id,
        external_id: "some external_id",
        first_name: "some first_name",
        last_name: "some last_name",
        source: :openphone
      }

      update_attrs = %{
        account_id: Discussit.AccountsFixtures.account_fixture().id,
        external_id: "some external_id",
        first_name: "some updated first_name",
        last_name: "some updated last_name",
        source: :openphone
      }

      contact = contact_fixture(create_attrs)
      assert {:ok, %Contact{}} = Contacts.upsert_contact(update_attrs)
      contact = Contacts.get_contact!(contact.id)
      assert contact.first_name == update_attrs.first_name
      assert contact.last_name == update_attrs.last_name
      assert contact.external_id == create_attrs.external_id
    end

    test "update_contact/2 with valid data updates the contact" do
      contact = contact_fixture()

      update_attrs = %{
        external_id: "some updated external_id",
        first_name: "some updated first_name",
        last_name: "some updated last_name",
        source: :openphone
      }

      assert {:ok, %Contact{} = contact} = Contacts.update_contact(contact, update_attrs)
      assert contact.external_id == "some updated external_id"
      assert contact.first_name == "some updated first_name"
      assert contact.last_name == "some updated last_name"
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
