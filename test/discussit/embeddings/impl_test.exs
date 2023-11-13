defmodule Discussit.Embeddings.ImplTest do
  use Discussit.DataCase
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney
  alias Discussit.Embeddings.Impl
  import Discussit.StatementsFixtures
  import Discussit.AccountsFixtures
  import Discussit.ConversationsFixtures

  describe "Embeddings" do
    setup do
      {:ok, _} = start_supervised(Discussit.Embeddings.ModelStatus)
      ExVCR.Config.filter_request_headers("Authorization")
      account = account_fixture(%{enable_embeddings: true})
      conversation = conversation_fixture(%{account_id: account.id})
      Discussit.Embeddings.ModelStatus.set(:started)
      %{account: account, conversation: conversation}
    end

    test "gets embeddings" do
      use_cassette("single_vector") do
        assert {:ok, %Pgvector{}} = Impl.get_embedding("Your mom")
      end
    end

    test "embeds a statement", %{conversation: conversation} do
      statement_fixture(%{conversation_id: conversation.id})

      use_cassette("single_vector") do
        assert [
                 %{
                   status: :ok,
                   embedding: %{status: :complete, vector: vector},
                   source: %{all_stopwords: false}
                 }
               ] = Impl.embed_statements()

        assert not is_nil(vector)
      end
    end

    test "embeds multiple statements", %{conversation: conversation} do
      Enum.map(1..2, fn _ -> statement_fixture(%{conversation_id: conversation.id}) end)

      use_cassette("single_vector") do
        Impl.embed_statements()
      end
    end

    test "embedded statements don't come back", %{conversation: conversation} do
      statement_fixture(%{conversation_id: conversation.id})

      use_cassette("single_vector") do
        Impl.embed_statements()
      end

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

      use_cassette("single_vector") do
        assert [%{status: :ok, source: %{all_stopwords: false}}] = Impl.embed_statements(100)
      end
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

      use_cassette("single_vector") do
        Impl.embed_statements()
        assert Discussit.Usages.list_usages() |> Enum.count() == 1
      end
    end

    test "setting the server status stops the flow", %{conversation: conversation} do
      statement_fixture(%{conversation_id: conversation.id})
      Discussit.Embeddings.ModelStatus.set(:not_started)
      assert [%{status: :model_not_started}] = Impl.embed_statements(100)
    end

    test "only embeds statements in accounts with embeddings enabled", context do
      %{conversation: conversation} = context
      %{id: statement_id} = statement_fixture(%{conversation_id: conversation.id})

      account = account_fixture(%{enable_embeddings: false})
      conversation_fixture(%{account_id: account.id})

      use_cassette("single_vector") do
        assert [%{embedding: %{statement_id: ^statement_id}}] = Impl.embed_statements()
      end
    end
  end
end
