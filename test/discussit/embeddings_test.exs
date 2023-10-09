defmodule Discussit.EmbeddingsTest do
  use Discussit.DataCase

  alias Discussit.Embeddings

  describe "embeddings" do
    alias Discussit.Embeddings.Embedding

    import Discussit.EmbeddingsFixtures

    @invalid_attrs %{vector: nil, status: nil}

    test "list_embeddings/0 returns all embeddings" do
      embedding = embedding_fixture()
      assert Embeddings.list_embeddings() == [embedding]
    end

    test "list_embeddings/0 returns the nearest embedding" do
      embedding_fixture(%{embedding: vector, status: :complete})
      embedding_fixture(%{embedding: opposite_vector, status: :complete})
      embedding_fixture(%{embedding: other_vector, status: :complete})
    end

    test "get_embedding!/1 returns the embedding with given id" do
      embedding = embedding_fixture()
      assert Embeddings.get_embedding!(embedding.id) == embedding
    end

    test "create_embedding/1 with valid data creates a embedding" do
      valid_attrs = %{vector: vector(), status: :created}

      assert {:ok, %Embedding{} = embedding} = Embeddings.create_embedding(valid_attrs)
      assert embedding.vector == Pgvector.new(vector())
    end

    test "create_embedding/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Embeddings.create_embedding(@invalid_attrs)
    end

    test "update_embedding/2 with valid data updates the embedding" do
      embedding = embedding_fixture()
      update_attrs = %{vector: other_vector()}

      assert {:ok, %Embedding{} = embedding} =
               Embeddings.update_embedding(embedding, update_attrs)

      assert embedding.vector == Pgvector.new(other_vector())
    end

    test "update_embedding/2 with invalid data returns error changeset" do
      embedding = embedding_fixture()
      assert {:error, %Ecto.Changeset{}} = Embeddings.update_embedding(embedding, @invalid_attrs)
      assert embedding == Embeddings.get_embedding!(embedding.id)
    end

    test "delete_embedding/1 deletes the embedding" do
      embedding = embedding_fixture()
      assert {:ok, %Embedding{}} = Embeddings.delete_embedding(embedding)
      assert_raise Ecto.NoResultsError, fn -> Embeddings.get_embedding!(embedding.id) end
    end

    test "change_embedding/1 returns a embedding changeset" do
      embedding = embedding_fixture()
      assert %Ecto.Changeset{} = Embeddings.change_embedding(embedding)
    end
  end
end
