defmodule Discussit.Accounts.ResetAccountModels do
  alias Discussit.Accounts.Account
  alias Discussit.{Models, Statements, Topics}

  def execute(%Account{id: account_id} = account) do
    [latest | rest] =
      Models.list_models(
        order_by: [inserted_at: :desc],
        filters: [account_id: account_id]
      )

    rest
    |> Enum.each(&Models.delete_model/1)

    with {:ok, model} <- Models.clear_model_s3_objects(latest),
         :ok <- delete_untitled_topics(account),
         :ok <- purge_trained_ids(account) do
      {:ok, model}
    end
  end

  defp delete_untitled_topics(account) do
    Topics.list_topics(filters: [account_id: account.id, title_is_nil: true])
    |> Enum.reduce_while(:ok, fn topic, _ ->
      case Topics.delete_topic(topic) do
        {:ok, _} -> {:cont, :ok}
        {:error, %{errors: [labelled_statements: _]}} -> {:cont, :ok}
        {:error, _} -> {:halt, :error}
      end
    end)
  end

  defp purge_trained_ids(account) do
    Statements.list_statements(filters: [account_id: account.id])
    |> Enum.each(fn statement ->
      Statements.update_statement(statement, %{trained_topic_id: nil})
    end)
  end
end
