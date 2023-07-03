defmodule OpenphoneRecorder.Summaries do
  import Ecto.Query, warn: false
  alias OpenphoneRecorder.Repo

  alias OpenphoneRecorder.Summaries.Summary

  def list_summaries(opts \\ []) do
    order_by = Keyword.get(opts, :order_by, [])
    preload = Keyword.get(opts, :preload, [])
    filters = Keyword.get(opts, :filters, [])

    Summary
    |> maybe_filter_by_before(filters[:before])
    |> order_by_lower(order_by[:tsrange_lower])
    |> preload(^preload)
    |> Repo.all()
  end

  defp maybe_filter_by_before(query, nil), do: query

  defp maybe_filter_by_before(query, before) do
    query
    |> where([s], fragment("upper(?)", s.tsrange) < ^before)
  end

  defp order_by_lower(query, nil), do: query

  defp order_by_lower(query, :asc),
    do: order_by(query, [s], asc: fragment("lower(?)", s.tsrange))

  defp order_by_lower(query, :desc),
    do: order_by(query, [s], desc: fragment("lower(?)", s.tsrange))

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
