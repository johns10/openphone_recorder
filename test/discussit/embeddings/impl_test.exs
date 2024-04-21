defmodule Discussit.Embeddings.ImplTest do
  use Discussit.DataCase
  alias Discussit.Embeddings.Impl
  import Discussit.StatementsFixtures
  import Discussit.AccountsFixtures
  import Discussit.ConversationsFixtures

  describe "Embeddings" do
    setup do
      account = account_fixture(%{enable_embeddings: true})
      conversation = conversation_fixture(%{account_id: account.id})
      %{account: account, conversation: conversation}
    end

    test "gets embeddings" do
      assert {:ok, %Pgvector{}} = Impl.get_embedding("Your mom")
    end

    test "embeds a statement", %{conversation: conversation} do
      statement_fixture(%{conversation_id: conversation.id})

      assert [
               %{
                 status: :ok,
                 embedding: %{status: :complete, vector: vector},
                 source: %{all_stopwords: false}
               }
             ] = Impl.embed_statements()

      assert not is_nil(vector)
    end

    test "embeds multiple statements", %{conversation: conversation} do
      Enum.map(1..2, fn _ -> statement_fixture(%{conversation_id: conversation.id}) end)
      Impl.embed_statements()
    end

    test "embedded statements don't come back", %{conversation: conversation} do
      statement_fixture(%{conversation_id: conversation.id})
      Impl.embed_statements()
      assert [] == Impl.embed_statements()
    end

    test "all stopwords filtering works", %{conversation: conversation} do
      content = "thanks yes"
      statement_fixture(%{conversation_id: conversation.id, content: content})

      assert [%{status: :skipped, source: %{all_stopwords: true}}] = Impl.embed_statements(100)
    end

    test "not all stopwords filtering works", %{conversation: conversation} do
      content = "I have a proposal to make"
      statement_fixture(%{conversation_id: conversation.id, content: content})

      assert [%{status: :ok, source: %{all_stopwords: false}}] = Impl.embed_statements(100)
    end

    test "integer filtering works", %{conversation: conversation} do
      content = "1234"
      statement_fixture(%{conversation_id: conversation.id, content: content})

      assert [%{status: :skipped, status_detail: "Integer", source: %{unprocessable: true}}] =
               Impl.embed_statements(100)
    end

    test "filtered statements don't come back", %{conversation: conversation} do
      content = "thanks yes"
      statement_fixture(%{conversation_id: conversation.id, content: content})
      Impl.embed_statements()
      assert [] = Impl.embed_statements()
    end

    test "usage gets created", %{conversation: conversation} do
      statement_fixture(%{conversation_id: conversation.id})

      Impl.embed_statements()
      assert Discussit.Usages.list_usages() |> Enum.count() == 1
    end

    test "only embeds statements in accounts with embeddings enabled", context do
      %{conversation: conversation} = context
      %{id: statement_id} = statement_fixture(%{conversation_id: conversation.id})

      account = account_fixture(%{enable_embeddings: false})
      conversation_fixture(%{account_id: account.id})

      assert [%{embedding: %{statement_id: ^statement_id}}] = Impl.embed_statements()
    end
  end
end
