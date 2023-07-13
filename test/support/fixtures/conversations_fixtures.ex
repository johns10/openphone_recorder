defmodule Discussit.ConversationsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Discussit.Conversations` context.
  """

  @doc """
  Generate a conversation.
  """
  def conversation_fixture(attrs \\ %{}) do
    {:ok, conversation} =
      attrs
      |> Enum.into(%{
        account_id: Discussit.AccountsFixtures.account_fixture().id,
        external_id: Ecto.UUID.generate(),
        source: :openphone
      })
      |> Discussit.Conversations.create_conversation()

    conversation
  end
end
