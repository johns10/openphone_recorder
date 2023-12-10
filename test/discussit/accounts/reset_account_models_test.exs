defmodule Discussit.Models.ResetModelTest do
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney
  use Discussit.DataCase
  alias Discussit.Accounts.ResetAccountModels
  alias Discussit.{Models, Topics, Statements}
  import Discussit.AccountsFixtures
  import Discussit.ModelsFixtures
  import Discussit.TopicsFixtures
  import Discussit.StatementsFixtures
  import Discussit.ConversationsFixtures

  describe "reset model" do
    test "base case" do
      account = account_fixture()

      use_cassette("reset_models") do
        old_model =
          model_fixture(%{id: "4989bedd-adf3-4a66-a1d0-86fce4f98e75", account_id: account.id})

        topic_fixture(%{model_id: old_model.id})
        old_topic = topic_fixture(%{model_id: old_model.id, title: "title"})

        model =
          model_fixture(%{id: "4989bedd-adf3-4a66-a1d0-86fce4f98e74", account_id: account.id})

        topic = topic_fixture(%{model_id: model.id})
        conversation = conversation_fixture(%{account_id: account.id})
        statement_fixture(%{trained_topic_id: topic.id, conversation_id: conversation.id})
        ResetAccountModels.execute(account)

        [remaining_model] = Models.list_models()
        assert remaining_model.id == model.id
        refute remaining_model.merge_object
        refute remaining_model.model_object

        topic_ids = Topics.list_topics() |> Enum.map(& &1.id)
        assert old_topic.id in topic_ids
        assert topic.id in topic_ids

        [%{trained_topic_id: nil}] = Statements.list_statements()
      end
    end
  end
end
