defmodule OpenphoneRecorder.Statements do
  import Ecto.Query, warn: false
  alias OpenphoneRecorder.Repo

  alias OpenphoneRecorder.Statements.Statement

  def list_statements(opts \\ []) do
    filters = Keyword.get(opts, :filters, [])
    order_by = Keyword.get(opts, :order_by, [])
    preloads = Keyword.get(opts, :preloads, [])

    Statement
    |> maybe_filter_by_conversation_id(filters[:conversation_id])
    |> maybe_order_by_occurred_at(order_by[:occurred_at])
    |> maybe_filter_by_not_summarizer_id(filters[:not_summarizer_id])
    |> maybe_filter_by_before(filters[:before])
    |> preload(^preloads)
    |> Repo.all()
  end

  def get_statement!(id), do: Repo.get!(Statement, id)

  defp maybe_filter_by_conversation_id(query, nil), do: query

  defp maybe_filter_by_conversation_id(query, conversation_id) do
    query
    |> where([s], s.conversation_id == ^conversation_id)
  end

  defp maybe_filter_by_not_summarizer_id(query, nil), do: query

  defp maybe_filter_by_not_summarizer_id(query, summarizer_id) do
    query
    |> join(:left, [s], sum in assoc(s, :summaries), as: :sum)
    |> where([sum: s], s.summarizer_id != ^summarizer_id or is_nil(s.summarizer_id))
  end

  defp maybe_filter_by_before(query, nil), do: query

  defp maybe_filter_by_before(query, before) do
    query
    |> where([s], s.occurred_at < ^before)
  end

  defp maybe_order_by_occurred_at(query, nil), do: query

  defp maybe_order_by_occurred_at(query, :desc) do
    query
    |> order_by([s], desc: s.occurred_at)
  end

  defp maybe_order_by_occurred_at(query, :asc) do
    query
    |> order_by([s], asc: s.occurred_at)
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
