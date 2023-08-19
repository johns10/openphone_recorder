defmodule Discussit.ConversationWorkerTest do
  use Discussit.DataCase
  alias Discussit.ConversationWorker
  import Discussit.ConversationsFixtures
  import Discussit.AccountsFixtures
  import Discussit.SummarizersFixtures

  describe "New Interviews Worker" do
    test "works" do
      conversation = conversation_fixture()
      account = account_fixture()

      assert {:ok, _pid} = ConversationWorker.new(%{conversation: conversation, account: account})
    end

    test "works when there's already an instance" do
      conversation = conversation_fixture()
      account = account_fixture()

      assert {:ok, pid} = ConversationWorker.new(%{conversation: conversation, account: account})
      assert {:ok, ^pid} = ConversationWorker.new(%{conversation: conversation, account: account})
    end
  end

  describe "Temporal Summarizers " do
    test "works" do
      conversation = conversation_fixture()
      account = account_fixture()
      daily_summarizer_fixture()
      weekly_summarizer_fixture()

      {:ok, _pid} = ConversationWorker.new(%{conversation: conversation, account: account})
    end
  end
end
