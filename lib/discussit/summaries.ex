defmodule Discussit.Summaries do
  import Ecto.Query, warn: false
  alias Discussit.Repo

  alias Discussit.Summaries.Summary

  def list_summaries(opts \\ []) do
    order_by = Keyword.get(opts, :order_by, [])
    preload = Keyword.get(opts, :preload, [])
    filters = Keyword.get(opts, :filters, [])
    limit = Keyword.get(opts, :limit, nil)

    Summary
    |> maybe_filter_by_before(filters[:before])
    |> maybe_filter_by_after(filters[:after])
    |> maybe_filter_by_level(filters[:level])
    |> order_by_lower(order_by[:summary_interval_lower])
    |> filter_by_conversation_id(filters[:conversation_id])
    |> maybe_limit(limit)
    |> preload(^preload)
    |> Repo.all()
  end

  defp maybe_filter_by_before(query, nil), do: query

  defp maybe_filter_by_before(query, before) do
    query
    |> where([s], fragment("upper(?)", s.summary_interval) < ^before)
  end

  defp maybe_filter_by_after(query, nil), do: query

  defp maybe_filter_by_after(query, upper) do
    query
    |> where([s], fragment("lower(?)", s.summary_interval) > ^upper)
  end

  defp maybe_filter_by_level(query, nil), do: query

  defp maybe_filter_by_level(query, level) do
    query
    |> where([s], s.level == ^level)
  end

  defp order_by_lower(query, nil), do: query

  defp order_by_lower(query, :asc),
    do: order_by(query, [s], asc: fragment("lower(?)", s.summary_interval))

  defp order_by_lower(query, :desc),
    do: order_by(query, [s], desc: fragment("lower(?)", s.summary_interval))

  defp filter_by_conversation_id(query, nil), do: query

  defp filter_by_conversation_id(query, conversation_id) do
    query
    |> join(:left, [s], cs in assoc(s, :conversation_summarizer), as: :cs)
    |> where([cs: cs], cs.conversation_id == ^conversation_id)
  end

  defp maybe_limit(query, nil), do: query
  defp maybe_limit(query, limit), do: limit(query, ^limit)

  def get_summary!(id), do: Repo.get!(Summary, id)

  def get_latest_summary!(conversation_id, level) do
    Summary
    |> join(:left, [s], cs in assoc(s, :conversation_summarizer), as: :cs)
    |> where([s, cs: cs], cs.conversation_id == ^conversation_id)
    |> where([s], s.level == ^level)
    |> order_by([s], desc: fragment("lower(?)", s.summary_interval))
    |> limit(1)
    |> Repo.all()
    |> case do
      [] -> nil
      [summary] -> summary
    end
  end

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
