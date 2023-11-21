defmodule Discussit.TopicsTest do
  use Discussit.DataCase

  alias Discussit.Topics

  describe "topics" do
    alias Discussit.Topics.Topic

    import Discussit.TopicsFixtures

    @invalid_attrs %{sentiment: nil, description: nil, model_title: nil}

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

    test "create_topic/1 with valid data creates a topic" do
      parent_topic = topic_fixture()

      valid_attrs = %{
        sentiment: 42,
        description: "some description",
        title: "some title",
        model_title: "some title",
        model_id: 1,
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

    test "change_topic/1 returns a topic changeset" do
      topic = topic_fixture()
      assert %Ecto.Changeset{} = Topics.change_topic(topic)
    end
  end
end
