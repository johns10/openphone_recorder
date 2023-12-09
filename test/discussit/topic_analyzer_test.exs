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
  import Discussit.EmbeddingsFixtures
  import Discussit.TopicsFixtures

  describe "Topic Analyzer initialization" do
    setup do
      account =
        account_fixture(%{id: "a4370693-d267-40aa-9b5e-5454cf7ac996", enable_embeddings: true})

      bucket = Application.get_env(:discussit, :bucket)
      object = TopicAnalyzer.object_path(account)

      on_exit(fn ->
        TopicAnalyzer.local_path(account) |> File.rm_rf()

        case ExAws.S3.head_object(bucket, object) |> ExAws.request() do
          {:ok, _} -> ExAws.S3.delete_object(bucket, object) |> ExAws.request()
          _ -> nil
        end
      end)

      %{account: account, bucket: bucket, object: object}
    end

    test "handles non-existent objects", %{account: account, bucket: bucket, object: object} do
      use_cassette("existing_object") do
        ExAws.S3.put_object(bucket, object, "")
        |> ExAws.request()

        assert {:error, "analyzer model already exists"} == TopicAnalyzer.init(account)
      end
    end

    test "creates the model", %{account: account} do
      use_cassette("no existing_object") do
        assert {:ok, _} = TopicAnalyzer.init(account)
      end
    end

    test "creates new topics, and matches the generated topics to the statements", %{
      account: account
    } do
      account_id = account.id
      conversation = conversation_fixture(%{account_id: account.id})
      statement = statement_fixture(%{conversation_id: conversation.id})
      embedding_fixture(%{statement_id: statement.id})

      use_cassette("no existing_object") do
        TopicAnalyzer.init(account)
      end

      assert [
               %{account_id: ^account_id, model_title: "Topic 1"},
               %{model_title: "Topic 2", id: topic_id}
             ] = Topics.list_topics()

      assert %{topic_id: ^topic_id} = Statements.get_statement!(statement.id)
    end

    @tag :integration
    test "empty initialization works", %{account: account, bucket: bucket, object: object} do
      Application.put_env(:discussit, :topic_analysis_server, Discussit.TopicAnalyzer.Local)
      {:ok, _} = start_supervised({Discussit.TopicAnalyzer.Server, %{}})
      :ok = Discussit.TopicAnalyzer.Server.ensure_server_started()

      conversation = conversation_fixture(%{account_id: account.id})

      case ExAws.S3.head_object(bucket, object) |> ExAws.request() do
        {:ok, _} -> ExAws.S3.delete_object(bucket, object) |> ExAws.request()
        _ -> nil
      end

      statements =
        (bathtub_cleaning_content() ++
           sink_cleaning_contant() ++
           floor_cleaning_content() ++
           toilet_cleaning_content() ++
           shower_cleaning_content() ++
           floor_cleaning_content_2() ++
           oven_cleaning_content() ++
           cabinet_cleaning_content() ++
           baseboard_cleaning_content() ++
           wall_cleaning_content() ++ ceiling_fan_cleaning_content())
        |> Enum.map(&statement_fixture(%{content: &1, conversation_id: conversation.id}))

      use_cassette("embedding_calls", match_requests_on: [:request_body]) do
        statements
        |> Enum.map(fn statement ->
          {:ok, vector} = Discussit.Embeddings.Impl.get_embedding(statement.content)
          embedding_fixture(%{statement_id: statement.id, vector: vector})
        end)
      end

      # use_cassette("no existing_object") do
      {:ok, results} = TopicAnalyzer.init(account)
      assert Enum.count(results) == Enum.count(statements)
      # end

      topics_count = Topics.list_topics() |> Enum.count() |> IO.inspect()
      assert topics_count < 45 and topics_count > 35

      assert Statements.list_statements()
             |> Enum.filter(&(&1.trained_topic_id != nil))
             |> Enum.count() > 0

      Discussit.TopicAnalyzer.Server.stop_server()
    end

    @tag :integration
    test "labelled initialization works", %{account: account, bucket: bucket, object: object} do
      Application.put_env(:discussit, :topic_analysis_server, Discussit.TopicAnalyzer.Local)
      {:ok, _} = start_supervised({Discussit.TopicAnalyzer.Server, %{}})
      :ok = Discussit.TopicAnalyzer.Server.ensure_server_started()

      conversation = conversation_fixture(%{account_id: account.id})

      bathtub_topic =
        topic_fixture(%{
          title: "Bathtub cleaning",
          topic_topic_model_id: 1,
          account_id: account.id
        })

      sink_topic =
        topic_fixture(%{title: "Sink cleaning", topic_model_id: 2, account_id: account.id})

      floor_topic =
        topic_fixture(%{title: "Floor cleaning", topic_model_id: 3, account_id: account.id})

      case ExAws.S3.head_object(bucket, object) |> ExAws.request() do
        {:ok, _} -> ExAws.S3.delete_object(bucket, object) |> ExAws.request()
        _ -> nil
      end

      bathtub_statements =
        bathtub_cleaning_content()
        |> Enum.map(
          &statement_fixture(%{
            content: &1,
            conversation_id: conversation.id,
            labelled_topic_id: bathtub_topic.id
          })
        )

      sink_statements =
        sink_cleaning_contant()
        |> Enum.map(
          &statement_fixture(%{
            content: &1,
            conversation_id: conversation.id,
            labelled_topic_id: sink_topic.id
          })
        )

      floor_statements =
        floor_cleaning_content()
        |> Enum.map(
          &statement_fixture(%{
            content: &1,
            conversation_id: conversation.id,
            labelled_topic_id: floor_topic.id
          })
        )

      statements = bathtub_statements ++ sink_statements ++ floor_statements

      use_cassette("embedding_calls", match_requests_on: [:request_body]) do
        statements
        |> Enum.map(fn statement ->
          {:ok, vector} = Discussit.Embeddings.Impl.get_embedding(statement.content)
          embedding_fixture(%{statement_id: statement.id, vector: vector})
        end)
      end

      use_cassette("no existing_object") do
        {:ok, _} = TopicAnalyzer.init(account)
      end

      topics_count = Topics.list_topics() |> Enum.count()
      assert topics_count == 14
    end

    @tag :integration
    test "label reuse", %{account: account, bucket: bucket, object: object} do
      Application.put_env(:discussit, :topic_analysis_server, Discussit.TopicAnalyzer.Local)
      {:ok, _} = start_supervised({Discussit.TopicAnalyzer.Server, %{}})
      :ok = Discussit.TopicAnalyzer.Server.ensure_server_started()

      conversation = conversation_fixture(%{account_id: account.id})

      case ExAws.S3.head_object(bucket, object) |> ExAws.request() do
        {:ok, _} -> ExAws.S3.delete_object(bucket, object) |> ExAws.request()
        _ -> nil
      end

      statements =
        (bathtub_cleaning_content() ++
           sink_cleaning_contant() ++
           floor_cleaning_content())
        |> Enum.map(&statement_fixture(%{content: &1, conversation_id: conversation.id}))

      use_cassette("embedding_calls", match_requests_on: [:request_body]) do
        statements
        |> Enum.map(fn statement ->
          {:ok, vector} = Discussit.Embeddings.Impl.get_embedding(statement.content)
          embedding_fixture(%{statement_id: statement.id, vector: vector})
        end)
      end

      use_cassette("no existing_object") do
        {:ok, results} = TopicAnalyzer.init(account)
        assert Enum.count(results) == Enum.count(statements)
      end

      topics_count = Topics.list_topics() |> Enum.count()
      assert topics_count in [12, 13, 14, 15]

      more_statements =
        (toilet_cleaning_content() ++
           shower_cleaning_content() ++
           floor_cleaning_content_2())
        |> Enum.map(&statement_fixture(%{content: &1, conversation_id: conversation.id}))

      use_cassette("embedding_calls", match_requests_on: [:request_body]) do
        more_statements
        |> Enum.map(fn statement ->
          {:ok, vector} = Discussit.Embeddings.Impl.get_embedding(statement.content)
          embedding_fixture(%{statement_id: statement.id, vector: vector})
        end)
      end

      use_cassette("no existing_object") do
        {:ok, results} = TopicAnalyzer.init(account)
        assert Enum.count(results) == Enum.count(statements ++ more_statements)
      end

      topics_count = Topics.list_topics() |> Enum.count()
      assert topics_count in [22, 23, 24, 25, 26, 27, 28]
    end
  end

  describe "Topic Analyzer training" do
    setup do
      account = account_fixture(%{id: "a4370693-d267-40aa-9b5e-5454cf7ac996"})
      bucket = Application.get_env(:discussit, :bucket)
      object = TopicAnalyzer.object_path(account)

      %{account: account, bucket: bucket, object: object}
    end

    test "training works", %{account: account} do
      conversation = conversation_fixture(%{account_id: account.id})
      statement = statement_fixture(%{conversation_id: conversation.id})
      embedding_fixture(%{statement_id: statement.id})

      use_cassette("no existing_object") do
        TopicAnalyzer.init(account)
      end

      statement_fixture(%{conversation_id: conversation.id})

      use_cassette("existing_object") do
        assert {:ok, [_]} = TopicAnalyzer.train(account)
      end
    end

    @tag :integration
    test "training", %{account: account} do
      Application.put_env(:discussit, :topic_analysis_server, Discussit.TopicAnalyzer.Local)
      conversation = conversation_fixture(%{account_id: account.id})

      # initial_statements =
      (floor_cleaning_content() ++ bathtub_cleaning_content())
      |> Enum.map(&statement_fixture(%{content: &1, conversation_id: conversation.id}))
      |> Enum.map(fn statement ->
        embedding_fixture(%{statement_id: statement.id})
        statement
      end)

      use_cassette("no existing_object") do
        TopicAnalyzer.init(account)
      end

      topics_after_initialization = Topics.list_topics() |> Enum.count()
      assert topics_after_initialization in 6..9

      # training_statements =
      (toilet_cleaning_content() ++ shower_cleaning_content())
      |> Enum.map(&statement_fixture(%{content: &1, conversation_id: conversation.id}))
      |> Enum.map(fn statement ->
        embedding_fixture(%{statement_id: statement.id})
        statement
      end)

      use_cassette("existing_object") do
        TopicAnalyzer.train(account)
      end

      topics_after_training = Topics.list_topics() |> Enum.count()
      assert topics_after_training in 6..9
      assert Statements.list_statements() |> Enum.all?(&(&1.topic_id != nil))
    end
  end
end
