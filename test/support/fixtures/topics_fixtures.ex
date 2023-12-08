defmodule Discussit.TopicsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Discussit.Topics` context.
  """

  @doc """
  Generate a topic.
  """
  def topic_fixture(attrs \\ %{}) do
    {:ok, topic} =
      attrs
      |> Enum.into(%{
        sentiment: 42,
        description: "some description",
        title: "some title",
        model_title: "some model title",
        topic_model_id: 1,
        account_id: Map.get(attrs, :account_id, nil)
      })
      |> Discussit.Topics.create_topic()

    topic
  end
end
