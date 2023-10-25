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
        summary: "some summary",
        title: "some title",
        model_title: "some model title",
        model_id: 1
      })
      |> Discussit.Topics.create_topic()

    topic
  end
end
