defmodule Discussit.AccountUsersTest do
  use Discussit.DataCase

  alias Discussit.AccountUsers

  describe "account_users" do
    alias Discussit.AccountUsers.AccountUser

    import Discussit.AccountUsersFixtures

    @invalid_attrs %{account_id: Ecto.UUID.generate(), user_id: Ecto.UUID.generate()}

    test "list_account_users/0 returns all account_users" do
      account_user = account_user_fixture()
      assert AccountUsers.list_account_users() == [account_user]
    end

    test "get_account_user!/1 returns the account_user with given id" do
      account_user = account_user_fixture()
      assert AccountUsers.get_account_user!(account_user.id) == account_user
    end

    test "create_account_user/1 with valid data creates a account_user" do
      valid_attrs = %{}

      assert {:ok, %AccountUser{}} = AccountUsers.create_account_user(valid_attrs)
    end

    test "create_account_user/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = AccountUsers.create_account_user(@invalid_attrs)
    end

    test "update_account_user/2 with valid data updates the account_user" do
      account_user = account_user_fixture()
      update_attrs = %{}

      assert {:ok, %AccountUser{}} = AccountUsers.update_account_user(account_user, update_attrs)
    end

    test "update_account_user/2 with invalid data returns error changeset" do
      account_user = account_user_fixture()

      assert {:error, %Ecto.Changeset{}} =
               AccountUsers.update_account_user(account_user, @invalid_attrs)

      assert account_user == AccountUsers.get_account_user!(account_user.id)
    end

    test "delete_account_user/1 deletes the account_user" do
      account_user = account_user_fixture()
      assert {:ok, %AccountUser{}} = AccountUsers.delete_account_user(account_user)
      assert_raise Ecto.NoResultsError, fn -> AccountUsers.get_account_user!(account_user.id) end
    end

    test "change_account_user/1 returns a account_user changeset" do
      account_user = account_user_fixture()
      assert %Ecto.Changeset{} = AccountUsers.change_account_user(account_user)
    end
  end
end
