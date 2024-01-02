defmodule Discussit.TopicAnalyzer.LocalTest do
  use Discussit.DataCase
  alias Discussit.TopicAnalyzer.Local

  describe "Local Python Server" do
    @tag :integration
    test "starting and works" do
      {:ok, pid} = Local.start()
      assert is_pid(pid)
      assert :ok = Local.stop(pid)
    end

    @tag :integration
    test "init model works" do
      Application.put_env(:discussit, :topic_analysis_server, Discussit.StubTopicAnalyzer)

      %{id: account_id} = account = Discussit.AccountsFixtures.account_fixture()
      %{id: model_id} = Discussit.ModelsFixtures.model_fixture(%{account_id: account_id})

      topic =
        Discussit.TopicsFixtures.topic_fixture(%{account_id: account_id, topic_model_id: 999})

      {:ok, pid} = Local.start_link(%{model_id: model_id, account_id: account_id, parent: self()})
      Ecto.Adapters.SQL.Sandbox.allow(Repo, self(), pid)

      statement =
        Discussit.StatementsFixtures.statement_fixture(%{labelled_topic_id: topic.id})
        |> Map.put(:labelled_topic, topic)
        |> Map.put(:embedding, %Discussit.Embeddings.Embedding{
          vector: Discussit.EmbeddingsFixtures.vector() |> Pgvector.new()
        })

      :ok = Local.init_model(pid, [statement], "")
      assert_receive({:done, [_]})
      :ok = :python.stop(pid)
      Application.put_env(:discussit, :topic_analysis_server, Discussit.TopicAnalyzer.Local)
    end
  end
end
