defmodule Discussit.CallsTest do
  use Discussit.DataCase

  alias Discussit.Calls

  describe "calls" do
    alias Discussit.Calls.Call

    import Discussit.CallsFixtures

    @invalid_attrs %{external_id: nil, source: nil, status: :not_valid_status}

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
      update_attrs = %{status: :transcribed, source: :openphone}

      assert {:ok, %Call{} = call} = Calls.update_call(call, update_attrs)
      assert call.status == :transcribed
      assert call.source == :openphone
    end

    test "update_call/2 with invalid data returns error changeset" do
      call = call_fixture()
      assert {:error, %Ecto.Changeset{}} = Calls.update_call(call, @invalid_attrs)
      assert call == Calls.get_call!(call.id)
    end

    test "update_call_recording/2 when call.call_recording is nil" do
      call = call_fixture(%{call_recording: nil})

      assert {:ok, %{call_recording: %{bucket: "test"}}} =
               Calls.update_call_recording(call, %{
                 call_recording: %{bucket: "test", key: "test", metadata: %{"type" => "value"}}
               })
    end

    test "update_call_recording/2 when call.call_recording is the same" do
      call =
        call_fixture(%{
          call_recording: %{bucket: "test", key: "test", metadata: %{"type" => "value"}}
        })

      assert {:ok, %{call_recording: %{bucket: "test"}}} =
               Calls.update_call_recording(call, %{
                 call_recording: %{bucket: "test", key: "test", metadata: %{"type" => "value"}}
               })
    end

    test "upsert_call/2 doesn't overwrite the record" do
      valid_attrs = %{external_id: "some external_id", source: :openphone}
      call = call_fixture(valid_attrs)
      assert {:ok, %Call{}} = Calls.upsert_call(valid_attrs)
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

    import Discussit.AccountsFixtures
    import Discussit.ConversationsFixtures

    test "calls_status/1 returns counts" do
      account = account_fixture()
      conversation = conversation_fixture(%{account_id: account.id})
      call_fixture(%{status: :file_uploaded, conversation_id: conversation.id})
      call_fixture(%{status: :transcribing, conversation_id: conversation.id})
      call_fixture(%{status: :transcribed, conversation_id: conversation.id})
      call_fixture(%{status: :transcribed, conversation_id: conversation.id})
      Calls.calls_status(%{conversation_id: conversation.id})
    end
  end
end
