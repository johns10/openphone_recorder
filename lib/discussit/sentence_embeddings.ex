defmodule Discussit.SentenceEmbeddings do
  @moduledoc """
  The SentenceEmbeddings context.
  """

  import Ecto.Query, warn: false
  alias Discussit.Repo

  alias Discussit.SentenceEmbeddings.SentenceEmbedding

  def list_sentence_embeddings do
    Repo.all(SentenceEmbedding)
  end

  def get_sentence_embedding!(id), do: Repo.get!(SentenceEmbedding, id)

  def create_sentence_embedding(attrs \\ %{}) do
    %SentenceEmbedding{}
    |> SentenceEmbedding.changeset(attrs)
    |> Repo.insert()
  end

  def update_sentence_embedding(%SentenceEmbedding{} = sentence_embedding, attrs) do
    sentence_embedding
    |> SentenceEmbedding.changeset(attrs)
    |> Repo.update()
  end

  def delete_sentence_embedding(%SentenceEmbedding{} = sentence_embedding) do
    Repo.delete(sentence_embedding)
  end

  def change_sentence_embedding(%SentenceEmbedding{} = sentence_embedding, attrs \\ %{}) do
    SentenceEmbedding.changeset(sentence_embedding, attrs)
  end
end
