defmodule OpenphoneRecorder.Summaries do
  import Ecto.Query, warn: false
  alias OpenphoneRecorder.Repo

  alias OpenphoneRecorder.Summaries.Summary

  def list_summaries(opts \\ []) do
    preload = Keyword.get(opts, :preload, [])
    filters = Keyword.get(opts, :filters, [])

    Summary
    |> maybe_filter_by_before(filters[:before])
    |> preload(^preload)
    |> Repo.all()
  end

  defp maybe_filter_by_before(query, nil), do: query

  defp maybe_filter_by_before(query, before) do
    query
    |> where([s], s.to < ^before)
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
