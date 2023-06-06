defmodule OpenphoneRecorder.PhoneNumbersTest do
  use OpenphoneRecorder.DataCase

  alias OpenphoneRecorder.PhoneNumbers

  describe "phone_numbers" do
    alias OpenphoneRecorder.PhoneNumbers.PhoneNumber

    import OpenphoneRecorder.PhoneNumbersFixtures

    @invalid_attrs %{external_id: nil, value: nil, source: nil}

    test "list_phone_numbers/0 returns all phone_numbers" do
      phone_number = phone_number_fixture()
      assert PhoneNumbers.list_phone_numbers() == [phone_number]
    end

    test "get_phone_number!/1 returns the phone_number with given id" do
      phone_number = phone_number_fixture()
      assert PhoneNumbers.get_phone_number!(phone_number.id) == phone_number
    end

    test "create_phone_number/1 with valid data creates a phone_number" do
      valid_attrs = %{
        external_id: "some external_id",
        value: "12566583456",
        source: :openphone
      }

      assert {:ok, %PhoneNumber{} = phone_number} = PhoneNumbers.create_phone_number(valid_attrs)
      assert phone_number.external_id == "some external_id"
      assert phone_number.value == %EctoPhoneNumber{e164: 12_566_583_456}
      assert phone_number.source == :openphone
    end

    test "upsert_phone_number/1 with valid data does nothing" do
      valid_attrs = %{
        external_id: "some updated external_id",
        value: "12566589999",
        source: :openphone
      }

      old_phone_number =
        phone_number_fixture(%{
          external_id: "some external_id",
          value: "12566589999",
          source: :openphone
        })

      assert {:ok, %PhoneNumber{} = phone_number} = PhoneNumbers.upsert_phone_number(valid_attrs)
      PhoneNumbers.list_phone_numbers()
      assert phone_number.external_id == old_phone_number.external_id
      assert phone_number.value == %EctoPhoneNumber{e164: 12_566_589_999}
      assert phone_number.source == :openphone
    end

    test "upsert_phone_number/1 when there is no external id updates external id" do
      valid_attrs = %{
        external_id: "some updated external_id",
        value: "12566589999",
        source: :openphone
      }

      phone_number_fixture(%{
        external_id: nil,
        value: "12566589999",
        source: :openphone
      })

      assert {:ok, %PhoneNumber{} = phone_number} = PhoneNumbers.upsert_phone_number(valid_attrs)
      PhoneNumbers.list_phone_numbers()
      assert phone_number.external_id == valid_attrs.external_id
      assert phone_number.value == %EctoPhoneNumber{e164: 12_566_589_999}
      assert phone_number.source == :openphone
    end

    test "create_phone_number/1 on an existing phone number raises properly" do
      valid_attrs = %{
        external_id: "some external_id",
        value: "12566583456",
        source: :openphone
      }

      assert {:ok, %PhoneNumber{} = phone_number} = PhoneNumbers.create_phone_number(valid_attrs)
      assert phone_number.external_id == "some external_id"
      assert phone_number.value == %EctoPhoneNumber{e164: 12_566_583_456}
      assert phone_number.source == :openphone
    end

    test "create_phone_number/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = PhoneNumbers.create_phone_number(@invalid_attrs)
    end

    test "update_phone_number/2 with valid data updates the phone_number" do
      phone_number = phone_number_fixture()

      update_attrs = %{
        external_id: "some updated external_id",
        value: "12566583457",
        source: :openphone
      }

      assert {:ok, %PhoneNumber{} = phone_number} =
               PhoneNumbers.update_phone_number(phone_number, update_attrs)

      assert phone_number.external_id == "some updated external_id"
      assert phone_number.value == %EctoPhoneNumber{e164: 12_566_583_457}
      assert phone_number.source == :openphone
    end

    test "update_phone_number/2 with invalid data returns error changeset" do
      phone_number = phone_number_fixture()

      assert {:error, %Ecto.Changeset{}} =
               PhoneNumbers.update_phone_number(phone_number, @invalid_attrs)

      assert phone_number == PhoneNumbers.get_phone_number!(phone_number.id)
    end

    test "delete_phone_number/1 deletes the phone_number" do
      phone_number = phone_number_fixture()
      assert {:ok, %PhoneNumber{}} = PhoneNumbers.delete_phone_number(phone_number)
      assert_raise Ecto.NoResultsError, fn -> PhoneNumbers.get_phone_number!(phone_number.id) end
    end

    test "change_phone_number/1 returns a phone_number changeset" do
      phone_number = phone_number_fixture()
      assert %Ecto.Changeset{} = PhoneNumbers.change_phone_number(phone_number)
    end
  end
end
