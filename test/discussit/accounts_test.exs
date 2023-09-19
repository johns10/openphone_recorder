defmodule Discussit.AccountsTest do
  alias Discussit.Credits
  use Discussit.DataCase

  alias Discussit.Accounts

  describe "accounts" do
    alias Discussit.Accounts.Account

    import Discussit.AccountsFixtures

    @invalid_attrs %{name: nil, plan: nil}

    test "list_accounts/0 returns all accounts" do
      account = account_fixture()
      assert Accounts.list_accounts() == [account]
    end

    test "get_account!/1 returns the account with given id" do
      account = account_fixture()
      assert Accounts.get_account!(account.id) == account
    end

    test "get_account!/1 returns the account with available credits" do
      account = account_fixture()
      Discussit.UsagesFixtures.usage_fixture(%{account_id: account.id})
      Discussit.CreditsFixtures.credit_fixture(%{account_id: account.id})
      account = Accounts.get_account!(account.id, includes: [available_credits: true])
      assert account.available_credits == -361.5
    end

    test "create_account/1 with valid data creates a account" do
      valid_attrs = %{
        name: "some name",
        plan: :free,
        openphone_signing_secret: "UEtrY29teEM4NVdTWkFwUzY3VEQyYVBkYW1jOFhqZ2g=",
        openai_api_key: "test key",
        timezone: "America/Chicago"
      }

      assert {:ok, %Account{} = account} = Accounts.create_account(valid_attrs)
      assert account.name == "some name"
      assert account.plan == :free
      assert account.openphone_signing_secret == "UEtrY29teEM4NVdTWkFwUzY3VEQyYVBkYW1jOFhqZ2g="
      assert account.openai_api_key == "test key"
    end

    test "create_account/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Accounts.create_account(@invalid_attrs)
    end

    test "update_account/2 with valid data updates the account" do
      account = account_fixture()

      update_attrs = %{
        name: "some updated name",
        plan: :basic,
        openphone_signing_secret: "updated secret",
        openai_api_key: "test key",
        timezone: "America/Chicago"
      }

      assert {:ok, %Account{} = account} = Accounts.update_account(account, update_attrs)
      assert account.name == "some updated name"
      assert account.plan == :basic
      assert account.openphone_signing_secret == "updated secret"
      assert account.openai_api_key == "test key"
    end

    test "update_account/2 with invalid data returns error changeset" do
      account = account_fixture()
      assert {:error, %Ecto.Changeset{}} = Accounts.update_account(account, @invalid_attrs)
      assert account == Accounts.get_account!(account.id)
    end

    test "delete_account/1 deletes the account" do
      account = account_fixture()
      assert {:ok, %Account{}} = Accounts.delete_account(account)
      assert_raise Ecto.NoResultsError, fn -> Accounts.get_account!(account.id) end
    end

    test "change_account/1 returns a account changeset" do
      account = account_fixture()
      assert %Ecto.Changeset{} = Accounts.change_account(account)
    end
  end
end
