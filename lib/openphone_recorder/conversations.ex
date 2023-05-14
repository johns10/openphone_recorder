defmodule OpenphoneRecorder.Conversations do
  import Ecto.Query, warn: false
  alias OpenphoneRecorder.Repo

  alias OpenphoneRecorder.Conversations.Conversation

  def list_conversations(opts \\ []) do
    preloads = Keyword.get(opts, :preloads, nil)

    Conversation
    |> maybe_preload(preloads)
    |> Repo.all()
  end

  def get_conversation!(id), do: Repo.get!(Conversation, id)

  def create_conversation(attrs \\ %{}) do
    %Conversation{}
    |> Conversation.changeset(attrs)
    |> Repo.insert()
  end

  def upsert_conversation(attrs \\ %{}) do
    changeset =
      %Conversation{}
      |> Conversation.changeset(attrs)

    changeset
    |> Repo.insert()
    |> case do
      {:error, %{errors: [id: {"has already been taken", _}]}} ->
        conversation =
          changeset
          |> Ecto.Changeset.get_field(:id)
          |> get_conversation!()

        {:ok, conversation}

      success ->
        success
    end
  end

  def delete_conversation(%Conversation{} = conversation) do
    Repo.delete(conversation)
  end

  def change_conversation(%Conversation{} = conversation, attrs \\ %{}) do
    Conversation.changeset(conversation, attrs)
  end

  defp maybe_preload(query, nil), do: query
  defp maybe_preload(query, preloads) do
    query
    |> preload(^preloads)
  end
end
