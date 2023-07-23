defmodule Discussit.StatementSummaries do
  @moduledoc """
  The StatementSummaries context.
  """

  import Ecto.Query, warn: false
  alias Discussit.Repo

  alias Discussit.StatementSummaries.StatementSummary

  @doc """
  Returns the list of statement_summaries.

  ## Examples

      iex> list_statement_summaries()
      [%StatementSummary{}, ...]

  """
  def list_statement_summaries do
    Repo.all(StatementSummary)
  end

  @doc """
  Gets a single statement_summary.

  Raises `Ecto.NoResultsError` if the Statement summary does not exist.

  ## Examples

      iex> get_statement_summary!(123)
      %StatementSummary{}

      iex> get_statement_summary!(456)
      ** (Ecto.NoResultsError)

  """
  def get_statement_summary!(id), do: Repo.get!(StatementSummary, id)

  @doc """
  Creates a statement_summary.

  ## Examples

      iex> create_statement_summary(%{field: value})
      {:ok, %StatementSummary{}}

      iex> create_statement_summary(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_statement_summary(attrs \\ %{}) do
    %StatementSummary{}
    |> StatementSummary.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a statement_summary.

  ## Examples

      iex> update_statement_summary(statement_summary, %{field: new_value})
      {:ok, %StatementSummary{}}

      iex> update_statement_summary(statement_summary, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_statement_summary(%StatementSummary{} = statement_summary, attrs) do
    statement_summary
    |> StatementSummary.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a statement_summary.

  ## Examples

      iex> delete_statement_summary(statement_summary)
      {:ok, %StatementSummary{}}

      iex> delete_statement_summary(statement_summary)
      {:error, %Ecto.Changeset{}}

  """
  def delete_statement_summary(%StatementSummary{} = statement_summary) do
    Repo.delete(statement_summary)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking statement_summary changes.

  ## Examples

      iex> change_statement_summary(statement_summary)
      %Ecto.Changeset{data: %StatementSummary{}}

  """
  def change_statement_summary(%StatementSummary{} = statement_summary, attrs \\ %{}) do
    StatementSummary.changeset(statement_summary, attrs)
  end
end
