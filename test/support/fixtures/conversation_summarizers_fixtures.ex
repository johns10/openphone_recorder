defmodule OpenphoneRecorder.ConversationSummarizersFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `OpenphoneRecorder.ConversationSummarizers` context.
  """

  @doc """
  Generate a conversation_summarizer.
  """
  import OpenphoneRecorder.ConversationsFixtures
  import OpenphoneRecorder.SummarizersFixtures

  def conversation_summarizer_fixture(attrs \\ %{}) do
    {:ok, conversation_summarizer} =
      attrs
      |> Enum.into(%{
        conversation_id: conversation_fixture().id,
        summarizer_id: summarizer_fixture().id
      })
      |> OpenphoneRecorder.ConversationSummarizers.create_conversation_summarizer()

    conversation_summarizer
  end
end
