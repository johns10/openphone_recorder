defmodule OpenphoneRecorder.CallsTest do
  use OpenphoneRecorder.DataCase

  alias OpenphoneRecorder.Calls

  describe "calls" do
    alias OpenphoneRecorder.Calls.Call

    import OpenphoneRecorder.CallsFixtures

    @invalid_attrs %{external_id: nil, source: nil}

    test "list_calls/0 returns all calls" do
      call = call_fixture()
      assert Calls.list_calls() == [call]
    end

    test "get_call!/1 returns the call with given id" do
      call = call_fixture()
      assert Calls.get_call!(call.id) == call
    end

    test "create_call/1 with valid data creates a call" do
      valid_attrs = %{external_id: "some external_id", source: :openphone}

      assert {:ok, %Call{} = call} = Calls.create_call(valid_attrs)
      assert call.external_id == "some external_id"
      assert call.source == :openphone
    end

    test "create_call/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Calls.create_call(@invalid_attrs)
    end

    test "update_call/2 with valid data updates the call" do
      call = call_fixture()
      update_attrs = %{external_id: "some updated external_id", source: :openphone}

      assert {:ok, %Call{} = call} = Calls.update_call(call, update_attrs)
      assert call.external_id == "some updated external_id"
      assert call.source == :openphone
    end

    test "update_call/2 with invalid data returns error changeset" do
      call = call_fixture()
      assert {:error, %Ecto.Changeset{}} = Calls.update_call(call, @invalid_attrs)
      assert call == Calls.get_call!(call.id)
    end

    test "delete_call/1 deletes the call" do
      call = call_fixture()
      assert {:ok, %Call{}} = Calls.delete_call(call)
      assert_raise Ecto.NoResultsError, fn -> Calls.get_call!(call.id) end
    end

    test "change_call/1 returns a call changeset" do
      call = call_fixture()
      assert %Ecto.Changeset{} = Calls.change_call(call)
    end
  end
end
