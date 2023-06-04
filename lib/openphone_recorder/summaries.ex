defmodule OpenphoneRecorder.Summaries do
  import Ecto.Query, warn: false
  alias OpenphoneRecorder.Repo

  alias OpenphoneRecorder.Summaries.Summary

  def list_summaries do
    Repo.all(Summary)
  end

  def get_summary!(id), do: Repo.get!(Summary, id)

  def create_summary(attrs \\ %{}) do
    %Summary{}
    |> Summary.changeset(attrs)
    |> Repo.insert()
  end

  def update_summary(%Summary{} = summary, attrs) do
    summary
    |> Summary.changeset(attrs)
    |> Repo.update()
  end

  def delete_summary(%Summary{} = summary) do
    Repo.delete(summary)
  end

  def change_summary(%Summary{} = summary, attrs \\ %{}) do
    Summary.changeset(summary, attrs)
  end
end
