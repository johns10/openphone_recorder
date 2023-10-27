defmodule Discussit.SentenceEmbeddingsTest do
  use Discussit.DataCase

  alias Discussit.SentenceEmbeddings

  describe "sentence_embeddings" do
    alias Discussit.SentenceEmbeddings.SentenceEmbedding

    import Discussit.SentenceEmbeddingsFixtures

    @invalid_attrs %{model: nil, status: nil, vector: nil}

    test "list_sentence_embeddings/0 returns all sentence_embeddings" do
      sentence_embedding = sentence_embedding_fixture()
      assert SentenceEmbeddings.list_sentence_embeddings() == [sentence_embedding]
    end

    test "get_sentence_embedding!/1 returns the sentence_embedding with given id" do
      sentence_embedding = sentence_embedding_fixture()

      assert SentenceEmbeddings.get_sentence_embedding!(sentence_embedding.id) ==
               sentence_embedding
    end

    test "create_sentence_embedding/1 with valid data creates a sentence_embedding" do
      valid_attrs = %{model: :"BAAI/bge-large-en-v1.5", status: :created, vector: vector()}

      assert {:ok, %SentenceEmbedding{} = sentence_embedding} =
               SentenceEmbeddings.create_sentence_embedding(valid_attrs)

      assert sentence_embedding.model == :"BAAI/bge-large-en-v1.5"
      assert sentence_embedding.status == :created
      assert sentence_embedding.vector == Pgvector.new(vector())
    end

    test "create_sentence_embedding/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} =
               SentenceEmbeddings.create_sentence_embedding(@invalid_attrs)
    end

    test "update_sentence_embedding/2 with valid data updates the sentence_embedding" do
      sentence_embedding = sentence_embedding_fixture()

      update_attrs = %{
        model: :"BAAI/bge-large-en-v1.5",
        status: :running,
        vector: other_vector()
      }

      assert {:ok, %SentenceEmbedding{} = sentence_embedding} =
               SentenceEmbeddings.update_sentence_embedding(sentence_embedding, update_attrs)

      assert sentence_embedding.model == :"BAAI/bge-large-en-v1.5"
      assert sentence_embedding.status == :running
      assert sentence_embedding.vector == Pgvector.new(other_vector())
    end

    test "update_sentence_embedding/2 with invalid data returns error changeset" do
      sentence_embedding = sentence_embedding_fixture()

      assert {:error, %Ecto.Changeset{}} =
               SentenceEmbeddings.update_sentence_embedding(sentence_embedding, @invalid_attrs)

      assert sentence_embedding ==
               SentenceEmbeddings.get_sentence_embedding!(sentence_embedding.id)
    end

    test "delete_sentence_embedding/1 deletes the sentence_embedding" do
      sentence_embedding = sentence_embedding_fixture()

      assert {:ok, %SentenceEmbedding{}} =
               SentenceEmbeddings.delete_sentence_embedding(sentence_embedding)

      assert_raise Ecto.NoResultsError, fn ->
        SentenceEmbeddings.get_sentence_embedding!(sentence_embedding.id)
      end
    end

    test "change_sentence_embedding/1 returns a sentence_embedding changeset" do
      sentence_embedding = sentence_embedding_fixture()
      assert %Ecto.Changeset{} = SentenceEmbeddings.change_sentence_embedding(sentence_embedding)
    end
  end
end
