defmodule OpenphoneRecorder.Summaries do
  @moduledoc """
  The Summaries context.
  """

  import Ecto.Query, warn: false
  alias OpenphoneRecorder.Repo

  alias OpenphoneRecorder.Summaries.Summary

  @doc """
  Returns the list of summaries.

  ## Examples

      iex> list_summaries()
      [%Summary{}, ...]

  """
  def list_summaries do
    Repo.all(Summary)
  end

  @doc """
  Gets a single summary.

  Raises `Ecto.NoResultsError` if the Summary does not exist.

  ## Examples

      iex> get_summary!(123)
      %Summary{}

      iex> get_summary!(456)
      ** (Ecto.NoResultsError)

  """
  def get_summary!(id), do: Repo.get!(Summary, id)

  @doc """
  Creates a summary.

  ## Examples

      iex> create_summary(%{field: value})
      {:ok, %Summary{}}

      iex> create_summary(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_summary(attrs \\ %{}) do
    %Summary{}
    |> Summary.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a summary.

  ## Examples

      iex> update_summary(summary, %{field: new_value})
      {:ok, %Summary{}}

      iex> update_summary(summary, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_summary(%Summary{} = summary, attrs) do
    summary
    |> Summary.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a summary.

  ## Examples

      iex> delete_summary(summary)
      {:ok, %Summary{}}

      iex> delete_summary(summary)
      {:error, %Ecto.Changeset{}}

  """
  def delete_summary(%Summary{} = summary) do
    Repo.delete(summary)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking summary changes.

  ## Examples

      iex> change_summary(summary)
      %Ecto.Changeset{data: %Summary{}}

  """
  def change_summary(%Summary{} = summary, attrs \\ %{}) do
    Summary.changeset(summary, attrs)
  end
end
