defmodule Discussit.Embeddings do
  @moduledoc """
  The Embeddings context.
  """

  import Pgvector.Ecto.Query
  import Ecto.Query, warn: false
  alias Discussit.Repo

  alias Discussit.Embeddings.Embedding

  def list_embeddings(opts \\ []) do
    order_by = Keyword.get(opts, :order_by, [])

    Embedding
    |> maybe_limit(opts[:limit])
    |> maybe_cosine_distance(order_by[:cosine_distance])
    |> Repo.all()
  end

  defp maybe_limit(query, nil), do: query
  defp maybe_limit(query, value), do: limit(query, ^value)

  defp maybe_cosine_distance(query, nil), do: query

  defp maybe_cosine_distance(query, embedding),
    do: order_by(query, [e], cosine_distance(e.vector, ^embedding))

  def get_embedding!(id), do: Repo.get!(Embedding, id)

  def create_embedding(attrs \\ %{}) do
    %Embedding{}
    |> Embedding.changeset(attrs)
    |> Repo.insert()
  end

  def update_embedding(%Embedding{} = embedding, attrs) do
    embedding
    |> Embedding.changeset(attrs)
    |> Repo.update()
  end

  def delete_embedding(%Embedding{} = embedding) do
    Repo.delete(embedding)
  end

  def change_embedding(%Embedding{} = embedding, attrs \\ %{}) do
    Embedding.changeset(embedding, attrs)
  end
end
