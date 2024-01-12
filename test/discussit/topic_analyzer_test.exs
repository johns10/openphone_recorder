defmodule Discussit.TopicAnalyzerTest do
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney
  use Discussit.DataCase
  use Discussit.TopicAnalyzerCase
  alias Discussit.Topics
  alias Discussit.Models
  alias Discussit.Statements
  alias Discussit.TopicAnalyzer
  import Discussit.AccountsFixtures
  import Discussit.ConversationsFixtures
  import Discussit.StatementsFixtures
  import Discussit.EmbeddingsFixtures
  import Discussit.TopicsFixtures
  import Discussit.ModelsFixtures

  defp base_setup() do
    account = account_fixture(%{enable_embeddings: true})
    bucket = Application.get_env(:discussit, :bucket)
    model_id = "65a52fad-e74d-4700-8e40-219bdc26743d"
    object = Models.model_path(%Models.Model{id: model_id})

    on_exit(fn ->
      case ExAws.S3.head_object(bucket, object) |> ExAws.request() do
        {:ok, _} -> ExAws.S3.delete_object(bucket, object) |> ExAws.request()
        _ -> nil
      end
    end)

    %{account: account, bucket: bucket, object: object, model_id: model_id}
  end

  describe "Stubbed python" do
    setup do
      Application.put_env(:discussit, :topic_analyzer_impl, Elixir.Discussit.StubTopicAnalyzer)

      on_exit(fn ->
        Application.put_env(:discussit, :topic_analyzer_impl, Elixir.Discussit.Local)
      end)

      base_setup()
    end

    test "handles existing model object", context do
      %{account: account, bucket: bucket, object: object, model_id: model_id} = context

      use_cassette("existing_object") do
        ExAws.S3.put_object(bucket, object, "") |> ExAws.request()
        assert {:ok, pid} = TopicAnalyzer.start_link(%{account: account})
        {:ok, %{model: model}} = TopicAnalyzer.initialize(pid, account, model_id: model_id)
        assert model.model_object == Models.model_path(model)
        assert model.merge_object == Models.merge_path(model)
      end
    end

    test "creates the model", %{account: account, model_id: model_id} do
      use_cassette("no existing_object") do
        assert {:ok, pid} = TopicAnalyzer.start_link(%{account: account})
        {:ok, %{model: model}} = TopicAnalyzer.initialize(pid, account, model_id: model_id)
        assert model.model_object == Models.model_path(model)
        assert model.merge_object == Models.merge_path(model)
      end
    end

    test "creates the hierarchy", %{account: account, model_id: model_id} do
      model = model_fixture(%{id: model_id})

      assert {:ok, pid} =
               TopicAnalyzer.start_link(%{
                 account_id: account.id,
                 from: self(),
                 model: model
               })

      send(pid, {:create_topic, %{'topic_model_id' => 1, 'keywords' => []}})
      send(pid, {:create_topic, %{'topic_model_id' => 2, 'keywords' => []}})
      send(pid, {:create_hierarchy_topic, %{'topic_model_id' => 3, 'keywords' => []}})
      send(pid, {:assign_hierarchy, %{'topic_model_id' => 1, 'parent_topic_model_id' => 3}})
      send(pid, {:assign_hierarchy, %{'topic_model_id' => 2, 'parent_topic_model_id' => 3}})
      %{topics: topics} = TopicAnalyzer.state(pid)
      assert %{id: parent_id} = Enum.find(topics, &(&1.topic_model_id == 3))

      assert [
               %{id: ^parent_id, topic_model_id: 3},
               %{topic_model_id: 2, parent_topic_id: ^parent_id},
               %{topic_model_id: 1, parent_topic_id: ^parent_id}
             ] = topics
    end

    test "trains a model", %{account: account, bucket: bucket, model_id: model_id} do
      file_path = './test/support/fixtures/text.txt'
      archive_path = './test/support/fixtures/file.zip'
      File.touch(file_path)
      {:ok, _filename} = :zip.create(archive_path, [file_path])

      last_model =
        %{account_id: account.id, id: "83e84c72-d524-4e93-8d29-d468b1b2a866"}
        |> model_fixture()

      use_cassette("old_object") do
        old_object = Models.model_path(last_model)
        ExAws.S3.put_object(bucket, old_object, File.read!(archive_path)) |> ExAws.request()
      end

      use_cassette("train_existing_model") do
        assert {:ok, pid} = TopicAnalyzer.start_link(%{account: account})
        {:ok, %{model: model}} = TopicAnalyzer.train(pid, account, model_id: model_id)
        assert model.model_object == Models.model_path(model)
        assert model.merge_object == Models.merge_path(model)
      end

      File.rm!(file_path)
      File.rm!(archive_path)
    end
  end

  describe "Topic Analyzer initialization" do
    setup do
      base_setup()
    end

    # test "creates new topics, and matches the generated topics to the statements", %{
    #   account: account,
    #   object: object
    # } do
    #   account_id = account.id
    #   conversation = conversation_fixture(%{account_id: account.id})
    #   statement = statement_fixture(%{conversation_id: conversation.id})
    #   embedding_fixture(%{statement_id: statement.id})

    #   use_cassette("no existing_object") do
    #     assert {:ok, _} = TopicAnalyzer.init(account, model_id: object)
    #   end

    #   assert [
    #            %{account_id: ^account_id, model_title: "Topic 1"},
    #            %{model_title: "Topic 2", id: topic_id}
    #          ] = Topics.list_topics()

    #   assert %{trained_topic_id: ^topic_id} = Statements.get_statement!(statement.id)
    # end

    @tag :integration
    test "empty initialization works", %{
      account: account,
      bucket: bucket,
      object: object,
      model_id: model_id
    } do
      conversation = conversation_fixture(%{account_id: account.id})

      case ExAws.S3.head_object(bucket, object) |> ExAws.request() do
        {:ok, _} -> ExAws.S3.delete_object(bucket, object) |> ExAws.request()
        _ -> nil
      end

      statements =
        bathtub_cleaning_content()
        |> Enum.map(&statement_fixture(%{content: &1, conversation_id: conversation.id}))

      use_cassette("embedding_calls", match_requests_on: [:request_body]) do
        statements
        |> Enum.map(fn statement ->
          {:ok, vector} = Discussit.Embeddings.Impl.get_embedding(statement.content)
          embedding_fixture(%{statement_id: statement.id, vector: vector})
        end)
      end

      use_cassette("no existing_object") do
        {:ok, pid} = TopicAnalyzer.start_link(%{})
        assert {:ok, results} = TopicAnalyzer.initialize(pid, account, model_id: model_id)
        assert Enum.count(results.statements) == Enum.count(statements)
      end

      topics_count = Topics.list_topics() |> Enum.count() |> IO.inspect()
      assert topics_count < 45 and topics_count > 35

      assert Statements.list_statements()
             |> Enum.filter(&(&1.trained_topic_id != nil))
             |> Enum.count() > 0

      assert %{topic_model_id: -1} =
               Topics.get_topic_by(%{topic_model_id: -1, account_id: account.id})

      assert [_model] = Models.list_models()
    end

    @tag :integration
    test "labelled initialization works", %{
      account: account,
      bucket: bucket,
      object: object,
      model_id: model_id
    } do
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

      use_cassette("topic_analyzer_init") do
        {:ok, pid} = TopicAnalyzer.start_link(%{})
        assert {:ok, _} = TopicAnalyzer.initialize(pid, account, model_id: model_id)
      end

      topics_count = Topics.list_topics() |> Enum.count()
      assert topics_count in 13..16
    end

    @tag :integration
    test "label reuse", %{account: account, bucket: bucket, object: object, model_id: model_id} do
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

      results =
        use_cassette("no existing_object") do
          {:ok, pid} = TopicAnalyzer.start_link(%{})
          assert {:ok, results} = TopicAnalyzer.initialize(pid, account, model_id: model_id)
          results
        end

      assert Enum.count(results.statements) == Enum.count(statements)

      %{id: first_model_id} = results.model
      topics = Topics.list_topics()
      topics_count = Enum.count(topics)
      assert topics_count in [12, 13, 14, 15]

      Statements.list_statements()
      |> Enum.map(fn s ->
        Statements.update_statement(s, %{labelled_topic_id: s.trained_topic_id})
      end)

      Discussit.Accounts.ResetAccountModels.execute(account)

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

      results =
        use_cassette("no existing_object") do
          {:ok, pid} = TopicAnalyzer.start_link(%{})
          assert {:ok, results} = TopicAnalyzer.initialize(pid, account, model_id: model_id)
          results
        end

      assert Enum.count(results.statements) == Enum.count(statements ++ more_statements)

      old_topics = Topics.list_topics(filters: [model_id: first_model_id])
      # The outlier topic isn't getting created in the first run
      assert Enum.count(old_topics) == topics_count

      new_model_id = results.model.id
      new_topics = Topics.list_topics(filters: [model_id: new_model_id])
      new_topics_count = Enum.count(new_topics)
      assert new_topics_count in [22, 23, 24, 25, 26, 27, 28]

      mapped_topics =
        new_topics
        |> Enum.filter(&(&1.from_topic_id != nil))

      assert Enum.count(mapped_topics) > 0
    end
  end

  describe "Topic Analyzer training" do
    setup do
      account = account_fixture(%{id: "a4370693-d267-40aa-9b5e-5454cf7ac996"})
      bucket = Application.get_env(:discussit, :bucket)
      object = "65a52fad-e74d-4700-8e40-219bdc26743d"

      %{account: account, bucket: bucket, object: object}
    end

    # test "training works", %{account: account, object: object} do
    #   conversation = conversation_fixture(%{account_id: account.id})
    #   statement = statement_fixture(%{conversation_id: conversation.id})
    #   embedding_fixture(%{statement_id: statement.id})

    #   use_cassette("no existing_object") do
    #     TopicAnalyzer.init(account, model_id: object)
    #   end

    #   statement_fixture(%{conversation_id: conversation.id})

    #   use_cassette("existing_object") do
    #     assert {:ok, [_]} = TopicAnalyzer.train(account)
    #   end
    # end

    @tag :integration
    test "training", %{account: account} do
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
