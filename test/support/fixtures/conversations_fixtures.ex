defmodule OpenphoneRecorder.ConversationsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `OpenphoneRecorder.Conversations` context.
  """

  @doc """
  Generate a conversation.
  """
  def conversation_fixture(attrs \\ %{}) do
    {:ok, conversation} =
      attrs
      |> Enum.into(%{
        external_id: Ecto.UUID.generate(),
        source: :openphone
      })
      |> OpenphoneRecorder.Conversations.create_conversation()

    conversation
  end
end
