defmodule Discussit.ConversationSummarizerPlansFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Discussit.ConversationSummarizerPlans` context.
  """

  @doc """
  Generate a conversation_summarizer_plan.
  """
  def conversation_summarizer_plan_fixture(attrs \\ %{}) do
    {:ok, conversation_summarizer_plan} =
      attrs
      |> Enum.into(%{
        name: "some name"
      })
      |> Discussit.ConversationSummarizerPlans.create_conversation_summarizer_plan()

    conversation_summarizer_plan
  end
end
