defmodule Discussit.UsagesTest do
  use Discussit.DataCase

  alias Discussit.Usages

  describe "usages" do
    alias Discussit.Usages.Usage

    import Discussit.UsagesFixtures

    @invalid_attrs %{meta: nil, model: nil, product: nil, provider: nil, total: nil}

    test "list_usages/0 returns all usages" do
      usage = usage_fixture()
      assert Usages.list_usages() == [usage]
    end

    test "get_usage!/1 returns the usage with given id" do
      usage = usage_fixture()
      assert Usages.get_usage!(usage.id) == usage
    end

    test "create_usage/1 with valid data creates a usage" do
      account = Discussit.AccountsFixtures.account_fixture()

      valid_attrs = %{
        meta: %{},
        model: :"gpt-3.5-turbo",
        product: :chat_completions,
        provider: :openai,
        total: 120.5,
        account_id: account.id
      }

      assert {:ok, %Usage{} = usage} = Usages.create_usage(valid_attrs)
      assert usage.meta == %{}
      assert usage.model == :"gpt-3.5-turbo"
      assert usage.product == :chat_completions
      assert usage.provider == :openai
      assert usage.total == 120.5
    end

    test "create_usage/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Usages.create_usage(@invalid_attrs)
    end

    test "update_usage/2 with valid data updates the usage" do
      usage = usage_fixture()

      update_attrs = %{
        meta: %{},
        model: :"whisper-1",
        product: :transcription,
        provider: :openai,
        total: 456.7
      }

      assert {:ok, %Usage{} = usage} = Usages.update_usage(usage, update_attrs)
      assert usage.meta == %{}
      assert usage.model == :"whisper-1"
      assert usage.product == :transcription
      assert usage.provider == :openai
      assert usage.total == 456.7
    end

    test "update_usage/2 with invalid data returns error changeset" do
      usage = usage_fixture()
      assert {:error, %Ecto.Changeset{}} = Usages.update_usage(usage, @invalid_attrs)
      assert usage == Usages.get_usage!(usage.id)
    end

    test "delete_usage/1 deletes the usage" do
      usage = usage_fixture()
      assert {:ok, %Usage{}} = Usages.delete_usage(usage)
      assert_raise Ecto.NoResultsError, fn -> Usages.get_usage!(usage.id) end
    end

    test "change_usage/1 returns a usage changeset" do
      usage = usage_fixture()
      assert %Ecto.Changeset{} = Usages.change_usage(usage)
    end
  end
end
