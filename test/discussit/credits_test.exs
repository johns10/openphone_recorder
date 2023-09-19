defmodule Discussit.CreditsTest do
  use Discussit.DataCase

  alias Discussit.Credits

  describe "credits" do
    alias Discussit.Credits.Credit

    import Discussit.CreditsFixtures

    @invalid_attrs %{product_id: nil, purchased_at: nil, quantity: nil}

    test "sum_credits/1 sums credits" do
      account = Discussit.AccountsFixtures.account_fixture()
      credit = credit_fixture(%{account_id: account.id})
      credit_two = credit_fixture(%{account_id: account.id})

      assert Credits.sum_credits(filters: [account_id: account.id]) ==
               credit.quantity + credit_two.quantity
    end

    test "list_credits/0 returns all credits" do
      credit = credit_fixture()
      assert Credits.list_credits() == [credit]
    end

    test "get_credit!/1 returns the credit with given id" do
      credit = credit_fixture()
      assert Credits.get_credit!(credit.id) == credit
    end

    test "create_credit/1 with valid data creates a credit" do
      valid_attrs = %{
        product_id: "some product_id",
        purchased_at: ~N[2023-09-17 11:52:00],
        quantity: 120.5
      }

      assert {:ok, %Credit{} = credit} = Credits.create_credit(valid_attrs)
      assert credit.product_id == "some product_id"
      assert credit.purchased_at == ~N[2023-09-17 11:52:00]
      assert credit.quantity == 120.5
    end

    test "create_credit/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Credits.create_credit(@invalid_attrs)
    end

    test "update_credit/2 with valid data updates the credit" do
      credit = credit_fixture()

      update_attrs = %{
        product_id: "some updated product_id",
        purchased_at: ~N[2023-09-18 11:52:00],
        quantity: 456.7
      }

      assert {:ok, %Credit{} = credit} = Credits.update_credit(credit, update_attrs)
      assert credit.product_id == "some updated product_id"
      assert credit.purchased_at == ~N[2023-09-18 11:52:00]
      assert credit.quantity == 456.7
    end

    test "update_credit/2 with invalid data returns error changeset" do
      credit = credit_fixture()
      assert {:error, %Ecto.Changeset{}} = Credits.update_credit(credit, @invalid_attrs)
      assert credit == Credits.get_credit!(credit.id)
    end

    test "delete_credit/1 deletes the credit" do
      credit = credit_fixture()
      assert {:ok, %Credit{}} = Credits.delete_credit(credit)
      assert_raise Ecto.NoResultsError, fn -> Credits.get_credit!(credit.id) end
    end

    test "change_credit/1 returns a credit changeset" do
      credit = credit_fixture()
      assert %Ecto.Changeset{} = Credits.change_credit(credit)
    end
  end
end
