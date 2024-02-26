defmodule Discussit.ConversationSummarizerPlansTest do
  use Discussit.DataCase

  alias Discussit.ConversationSummarizerPlans

  describe "conversation_summarizer_plan" do
    alias Discussit.ConversationSummarizerPlans.ConversationSummarizerPlan

    import Discussit.ConversationSummarizerPlansFixtures

    @invalid_attrs %{name: nil}

    test "list_conversation_summarizer_plan/0 returns all conversation_summarizer_plan" do
      conversation_summarizer_plan = conversation_summarizer_plan_fixture()
      assert ConversationSummarizerPlans.list_conversation_summarizer_plan() == [conversation_summarizer_plan]
    end

    test "get_conversation_summarizer_plan!/1 returns the conversation_summarizer_plan with given id" do
      conversation_summarizer_plan = conversation_summarizer_plan_fixture()
      assert ConversationSummarizerPlans.get_conversation_summarizer_plan!(conversation_summarizer_plan.id) == conversation_summarizer_plan
    end

    test "create_conversation_summarizer_plan/1 with valid data creates a conversation_summarizer_plan" do
      valid_attrs = %{name: "some name"}

      assert {:ok, %ConversationSummarizerPlan{} = conversation_summarizer_plan} = ConversationSummarizerPlans.create_conversation_summarizer_plan(valid_attrs)
      assert conversation_summarizer_plan.name == "some name"
    end

    test "create_conversation_summarizer_plan/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = ConversationSummarizerPlans.create_conversation_summarizer_plan(@invalid_attrs)
    end

    test "update_conversation_summarizer_plan/2 with valid data updates the conversation_summarizer_plan" do
      conversation_summarizer_plan = conversation_summarizer_plan_fixture()
      update_attrs = %{name: "some updated name"}

      assert {:ok, %ConversationSummarizerPlan{} = conversation_summarizer_plan} = ConversationSummarizerPlans.update_conversation_summarizer_plan(conversation_summarizer_plan, update_attrs)
      assert conversation_summarizer_plan.name == "some updated name"
    end

    test "update_conversation_summarizer_plan/2 with invalid data returns error changeset" do
      conversation_summarizer_plan = conversation_summarizer_plan_fixture()
      assert {:error, %Ecto.Changeset{}} = ConversationSummarizerPlans.update_conversation_summarizer_plan(conversation_summarizer_plan, @invalid_attrs)
      assert conversation_summarizer_plan == ConversationSummarizerPlans.get_conversation_summarizer_plan!(conversation_summarizer_plan.id)
    end

    test "delete_conversation_summarizer_plan/1 deletes the conversation_summarizer_plan" do
      conversation_summarizer_plan = conversation_summarizer_plan_fixture()
      assert {:ok, %ConversationSummarizerPlan{}} = ConversationSummarizerPlans.delete_conversation_summarizer_plan(conversation_summarizer_plan)
      assert_raise Ecto.NoResultsError, fn -> ConversationSummarizerPlans.get_conversation_summarizer_plan!(conversation_summarizer_plan.id) end
    end

    test "change_conversation_summarizer_plan/1 returns a conversation_summarizer_plan changeset" do
      conversation_summarizer_plan = conversation_summarizer_plan_fixture()
      assert %Ecto.Changeset{} = ConversationSummarizerPlans.change_conversation_summarizer_plan(conversation_summarizer_plan)
    end
  end
end
