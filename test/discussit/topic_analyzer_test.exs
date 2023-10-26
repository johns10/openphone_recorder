defmodule Discussit.TopicAnalyzerTest do
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney
  use Discussit.DataCase
  use Discussit.TopicAnalyzerCase
  alias Discussit.Topics
  alias Discussit.Statements
  alias Discussit.TopicAnalyzer
  import Discussit.AccountsFixtures
  import Discussit.ConversationsFixtures
  import Discussit.StatementsFixtures

  describe "Topic Analyzer initialization" do
    setup do
      account = account_fixture(%{id: "a4370693-d267-40aa-9b5e-5454cf7ac996"})
      bucket = Application.get_env(:discussit, :bucket)
      object = TopicAnalyzer.model_path(account)

      %{account: account, bucket: bucket, object: object}
    end

    test "handles non-existent objects", %{account: account, bucket: bucket, object: object} do
      use_cassette("existing_object") do
        ExAws.S3.put_object(bucket, object, "")
        |> ExAws.request()

        assert {:error, "analyzer model already exists"} == TopicAnalyzer.init(account)
      end
    end

    test "creates the model", %{account: account, bucket: bucket, object: object} do
      use_cassette("no existing_object") do
        assert {:ok, _} = TopicAnalyzer.init(account)
      end

      # case ExAws.S3.head_object(bucket, object) |> ExAws.request() do
      #   {:ok, _} -> ExAws.S3.delete_object(bucket, object) |> ExAws.request()
      #   _ -> nil
      # end
    end

    test "creates new topics, and matches the generated topics to the statements", %{
      account: account,
      bucket: bucket,
      object: object
    } do
      account_id = account.id
      conversation = conversation_fixture(%{account_id: account.id})
      statement = statement_fixture(%{conversation_id: conversation.id})

      use_cassette("no existing_object") do
        TopicAnalyzer.init(account)
      end

      assert [
               %{account_id: ^account_id, model_title: "Topic 1"},
               %{model_title: "Topic 2", id: topic_id}
             ] = Topics.list_topics()

      assert %{topic_id: ^topic_id} = Statements.get_statement!(statement.id)

      # case ExAws.S3.head_object(bucket, object) |> ExAws.request() do
      #   {:ok, _} -> ExAws.S3.delete_object(bucket, object) |> ExAws.request()
      #   _ -> nil
      # end
    end

    @tag :integration
    test "integration", %{account: account} do
      Application.put_env(:discussit, :topic_analysis_provider, Discussit.TopicAnalyzer.Local)

      conversation = conversation_fixture(%{account_id: account.id})

      statements =
        (floor_cleaning_content() ++ bathtub_cleaning_content())
        |> Enum.map(&statement_fixture(%{content: &1, conversation_id: conversation.id}))

      use_cassette("no existing_object") do
        {:ok, results} = TopicAnalyzer.init(account)
        assert Enum.count(results) == Enum.count(statements)
      end

      assert (Topics.list_topics() |> Enum.count()) in 7..9
      assert Statements.list_statements() |> Enum.all?(&(&1.topic_id != nil))
    end
  end
end
