defmodule OpenphoneRecorder.Statements do
  import Ecto.Query, warn: false
  alias OpenphoneRecorder.Repo

  alias OpenphoneRecorder.Statements.Statement

  def list_statements do
    Repo.all(Statement)
  end

  def get_statement!(id), do: Repo.get!(Statement, id)

  def create_statement(attrs \\ %{}) do
    %Statement{}
    |> Statement.changeset(attrs)
    |> Repo.insert()
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
