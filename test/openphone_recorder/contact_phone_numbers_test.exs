defmodule OpenphoneRecorder.ContactPhoneNumbersTest do
  use OpenphoneRecorder.DataCase

  alias OpenphoneRecorder.ContactPhoneNumbers

  describe "contact_phone_numbers" do
    alias OpenphoneRecorder.ContactPhoneNumbers.ContactPhoneNumber

    import OpenphoneRecorder.ContactPhoneNumbersFixtures
    import OpenphoneRecorder.PhoneNumbersFixtures
    import OpenphoneRecorder.ContactsFixtures

    @invalid_attrs %{contact_id: Ecto.UUID.generate()}

    test "list_contact_phone_numbers/0 returns all contact_phone_numbers" do
      contact_phone_number = contact_phone_number_fixture()
      assert ContactPhoneNumbers.list_contact_phone_numbers() == [contact_phone_number]
    end

    test "get_contact_phone_number!/1 returns the contact_phone_number with given id" do
      contact_phone_number = contact_phone_number_fixture()

      assert ContactPhoneNumbers.get_contact_phone_number!(contact_phone_number.id) ==
               contact_phone_number
    end

    test "create_contact_phone_number/1 with valid data creates a contact_phone_number" do
      contact = contact_fixture()
      phone_number = phone_number_fixture()
      valid_attrs = %{contact_id: contact.id, phone_number_id: phone_number.id}

      assert {:ok, %ContactPhoneNumber{} = contact_phone_number} =
               ContactPhoneNumbers.create_contact_phone_number(valid_attrs)

      assert contact_phone_number.phone_number_id == phone_number.id
      assert contact_phone_number.contact_id == contact.id
    end

    test "create_contact_phone_number/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} =
               ContactPhoneNumbers.create_contact_phone_number(@invalid_attrs)
    end

    test "update_contact_phone_number/2 with valid data updates the contact_phone_number" do
      contact_phone_number = contact_phone_number_fixture()
      contact = contact_fixture()
      phone_number = phone_number_fixture()
      update_attrs = %{contact_id: contact.id, phone_number_id: phone_number.id}

      assert {:ok, %ContactPhoneNumber{} = contact_phone_number} =
               ContactPhoneNumbers.update_contact_phone_number(contact_phone_number, update_attrs)

      assert contact_phone_number.phone_number_id == phone_number.id
      assert contact_phone_number.contact_id == contact.id
    end

    test "get_or_insert_contact_phone_number/1 with valid data creates a contact_phone_number" do
      contact = contact_fixture()
      phone_number = phone_number_fixture()
      valid_attrs = %{contact_id: contact.id, phone_number_id: phone_number.id}
      contact_phone_number_fixture(valid_attrs)

      assert {:ok, %ContactPhoneNumber{} = contact_phone_number} =
               ContactPhoneNumbers.get_or_insert_contact_phone_number(valid_attrs)

      assert contact_phone_number.phone_number_id == phone_number.id
      assert contact_phone_number.contact_id == contact.id
    end

    test "update_contact_phone_number/2 with invalid data returns error changeset" do
      contact_phone_number = contact_phone_number_fixture()

      assert {:error, %Ecto.Changeset{}} =
               ContactPhoneNumbers.update_contact_phone_number(
                 contact_phone_number,
                 @invalid_attrs
               )

      assert contact_phone_number ==
               ContactPhoneNumbers.get_contact_phone_number!(contact_phone_number.id)
    end

    test "delete_contact_phone_number/1 deletes the contact_phone_number" do
      contact_phone_number = contact_phone_number_fixture()

      assert {:ok, %ContactPhoneNumber{}} =
               ContactPhoneNumbers.delete_contact_phone_number(contact_phone_number)

      assert_raise Ecto.NoResultsError, fn ->
        ContactPhoneNumbers.get_contact_phone_number!(contact_phone_number.id)
      end
    end

    test "change_contact_phone_number/1 returns a contact_phone_number changeset" do
      contact_phone_number = contact_phone_number_fixture()

      assert %Ecto.Changeset{} =
               ContactPhoneNumbers.change_contact_phone_number(contact_phone_number)
    end
  end
end
