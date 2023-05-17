defmodule OpenphoneRecorder.Statements do
  import Ecto.Query, warn: false
  alias OpenphoneRecorder.Repo

  alias OpenphoneRecorder.Statements.Statement

  def list_statements(opts \\ []) do
    filters = Keyword.get(opts, :filters, [])

    Statement
    |> maybe_filter_by_conversation_id(filters[:conversation_id])
    |> Repo.all()
  end

  def get_statement!(id), do: Repo.get!(Statement, id)


  defp maybe_filter_by_conversation_id(query, nil), do: query

  defp maybe_filter_by_conversation_id(query, conversation_id) do
    query
    |> where([s], s.conversation_id == ^conversation_id)
  end

  def create_statement(attrs \\ %{}) do
    %Statement{}
    |> Statement.changeset(attrs)
    |> Repo.insert()
  end

  def upsert_statement(attrs \\ %{}) do
    changeset =
      %Statement{}
      |> Statement.changeset(attrs)

    changeset
    |> Repo.insert()
    |> case do
      {:error, %{errors: [id: {"has already been taken", _}]}} ->
        statement =
          changeset
          |> Ecto.Changeset.get_field(:id)
          |> get_statement!()

        {:ok, statement}

      success ->
        success
    end
  end

  def update_statement(%Statement{} = statement, attrs) do
    statement
    |> Statement.changeset(attrs)
    |> Repo.update()
  end

  def delete_statement(%Statement{} = statement) do
    Repo.delete(statement)
  end

  def change_statement(%Statement{} = statement, attrs \\ %{}) do
    Statement.changeset(statement, attrs)
  end
end
