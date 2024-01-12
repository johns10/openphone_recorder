defmodule Discussit.TopicsTest do
  use Discussit.DataCase

  alias Discussit.Topics
  alias Discussit.Statements

  describe "topics" do
    alias Discussit.Topics.Topic
    alias Discussit.Statements.Statement

    import Discussit.TopicsFixtures
    import Discussit.StatementsFixtures
    import Discussit.AccountsFixtures

    @invalid_attrs %{topic_model_id: "a string"}

    test "list_topics/0 returns all topics" do
      topic = topic_fixture()
      assert Topics.list_topics() == [topic]
    end

    test "list_topics/1 returns topics with nil title" do
      topic = topic_fixture(%{title: nil})
      topic_fixture()
      assert Topics.list_topics(filters: [title_is_nil: true]) == [topic]
    end

    test "get_topic!/1 returns the topic with given id" do
      topic = topic_fixture()
      assert Topics.get_topic!(topic.id) == topic
    end

    test "include_previous_versions" do
      account = account_fixture()
      %{id: id_none} = topic_fixture(%{account_id: account.id, topic_model_id: 4})
      %{id: id_one} = topic_fixture(%{account_id: account.id, topic_model_id: 5})

      %{id: id_two} =
        topic_fixture(%{account_id: account.id, topic_model_id: 6, from_topic_id: id_one})

      %{id: id_three} =
        topic_fixture(%{account_id: account.id, topic_model_id: 7, from_topic_id: id_two})

      topics = Topics.list_topics(filters: [previous_versions: id_three])

      assert Enum.count(topics) == 3
      assert %{id: ^id_one} = Enum.find(topics, &(&1.id == id_one))
      assert %{id: ^id_two} = Enum.find(topics, &(&1.id == id_two))
      assert %{id: ^id_three} = Enum.find(topics, &(&1.id == id_three))
      assert is_nil(Enum.find(topics, &(&1.id == id_none)))
    end

    test "hierarchy filter" do
      h_topic = topic_fixture(%{hierarchy?: true})
      topic = topic_fixture(%{hierarchy?: false})

      assert [^h_topic] = Topics.list_topics(filters: [hierarchy?: true])
      assert [^topic] = Topics.list_topics(filters: [hierarchy?: false])
    end

    test "get_topic_by/1 returns the topic with the given model id" do
      account = account_fixture()
      topic = topic_fixture(%{account_id: account.id, topic_model_id: 5})
      assert Topics.get_topic_by(%{account_id: account.id, topic_model_id: 5}) == topic
    end

    test "create_topic/1 with valid data creates a topic" do
      parent_topic = topic_fixture()

      valid_attrs = %{
        sentiment: 42,
        description: "some description",
        title: "some title",
        model_title: "some title",
        topic_model_id: 1,
        parent_topic_id: parent_topic.id
      }

      assert {:ok, %Topic{} = topic} = Topics.create_topic(valid_attrs)
      assert topic.sentiment == 42
      assert topic.description == "some description"
      assert topic.title == "some title"
    end

    test "create_topic/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Topics.create_topic(@invalid_attrs)
    end

    test "update_topic/2 with valid data updates the topic" do
      parent_topic = topic_fixture()
      topic = topic_fixture()

      update_attrs = %{
        sentiment: 43,
        description: "some updated description",
        title: "some updated title",
        parent_topic_id: parent_topic.id
      }

      assert {:ok, %Topic{} = topic} = Topics.update_topic(topic, update_attrs)
      assert topic.sentiment == 43
      assert topic.description == "some updated description"
      assert topic.title == "some updated title"
    end

    test "update_topic/2 with invalid data returns error changeset" do
      topic = topic_fixture()
      assert {:error, %Ecto.Changeset{}} = Topics.update_topic(topic, @invalid_attrs)
      assert topic == Topics.get_topic!(topic.id)
    end

    test "delete_topic/1 deletes the topic" do
      topic = topic_fixture()
      assert {:ok, %Topic{}} = Topics.delete_topic(topic)
      assert_raise Ecto.NoResultsError, fn -> Topics.get_topic!(topic.id) end
    end

    test "delete_topic/1 deletes a topic and dereferences statement with trained_topic_id" do
      topic = topic_fixture()
      statement = statement_fixture(%{trained_topic_id: topic.id})
      assert {:ok, %Topic{}} = Topics.delete_topic(topic)
      assert %Statement{trained_topic_id: nil} = Statements.get_statement!(statement.id)
    end

    test "delete_topic/1 fails when a statement has labelled_topic_id" do
      topic = topic_fixture()
      statement = statement_fixture(%{labelled_topic_id: topic.id})
      assert {:error, %{errors: [labelled_statements: _]}} = Topics.delete_topic(topic)
      assert statement == Statements.get_statement!(statement.id)
    end

    test "change_topic/1 returns a topic changeset" do
      topic = topic_fixture()
      assert %Ecto.Changeset{} = Topics.change_topic(topic)
    end
  end
end
