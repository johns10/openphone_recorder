defmodule Discussit.Statements do
  import Ecto.Query, warn: false
  alias Discussit.Repo

  alias Discussit.Statements.Statement

  def list_statements(opts \\ []) do
    filters = Keyword.get(opts, :filters, [])
    order_by = Keyword.get(opts, :order_by, [])
    preloads = Keyword.get(opts, :preloads, [])

    Statement
    |> maybe_filter_by_call_id(filters[:call_id])
    |> maybe_filter_by_conversation_id(filters[:conversation_id])
    |> maybe_filter_by_meeting_id(filters[:meeting_id])
    |> maybe_filter_by_account_id(filters[:account_id])
    |> maybe_filter_by_topic_id(filters[:topic_id])
    |> maybe_order_by_occurred_at(order_by[:occurred_at])
    |> maybe_order_by_representative(order_by[:representative])
    |> maybe_filter_by_not_summarizer_id(filters[:not_summarizer_id])
    |> maybe_filter_by_before(filters[:before])
    |> maybe_filter_by_all_stopwords(filters[:all_stopwords])
    |> maybe_filter_by_embedding_enabled(filters[:embedding_enabled])
    |> maybe_filter_nil_topic_id(filters[:nil_topic_id])
    |> maybe_filter_embedded(filters[:embedded])
    |> maybe_filter_cumulative_content_length(filters[:cumulative_content_length])
    |> maybe_limit(opts[:limit])
    |> maybe_offset(opts[:offset])
    |> preload(^preloads)
    |> handle_query(opts[:count])
  end

  def get_statement!(id, opts \\ []) do
    preloads = Keyword.get(opts, :preloads, [])

    Statement
    |> preload(^preloads)
    |> Repo.get!(id)
  end

  defp maybe_filter_by_conversation_id(query, nil), do: query

  defp maybe_filter_by_conversation_id(query, conversation_id) do
    query
    |> where([s], s.conversation_id == ^conversation_id)
  end

  defp maybe_filter_by_meeting_id(query, nil), do: query

  defp maybe_filter_by_meeting_id(query, meeting_id) do
    query
    |> where([s], s.meeting_id == ^meeting_id)
  end

  defp maybe_filter_by_account_id(query, nil), do: query

  defp maybe_filter_by_account_id(query, account_id) do
    query
    |> join(:left, [s], c in assoc(s, :conversation), as: :conversation)
    |> where([conversation: c], c.account_id == ^account_id)
  end

  defp maybe_filter_by_topic_id(query, nil), do: query

  defp maybe_filter_by_topic_id(query, topic_id) do
    query
    |> where([s], s.labelled_topic_id == ^topic_id)
    |> or_where([s], s.trained_topic_id == ^topic_id)
  end

  defp maybe_filter_by_call_id(query, nil), do: query

  defp maybe_filter_by_call_id(query, call_id) do
    query
    |> where([s], s.call_id == ^call_id)
  end

  defp maybe_filter_by_all_stopwords(query, nil), do: query

  defp maybe_filter_by_all_stopwords(query, true),
    do: where(query, [s], s.all_stopwords == true)

  defp maybe_filter_by_all_stopwords(query, false),
    do:
      where(query, [s], s.all_stopwords == false)
      |> or_where([s], is_nil(s.all_stopwords))

  defp maybe_filter_by_embedding_enabled(query, nil), do: query

  defp maybe_filter_by_embedding_enabled(query, true),
    do:
      query
      |> join(:left, [s], c in assoc(s, :conversation), as: :conversation)
      |> join(:left, [conversation: c], a in assoc(c, :account), as: :account)
      |> where([account: a], a.enable_embeddings == true)

  defp maybe_filter_by_embedding_enabled(query, false),
    do:
      query
      |> join(:left, [s], c in assoc(s, :conversation), as: :conversation)
      |> join(:left, [conversation: c], a in assoc(c, :account), as: :account)
      |> where([account: a], a.enable_embeddings == true)
      |> or_where([account: a], is_nil(a.enable_embeddings))

  defp maybe_filter_nil_topic_id(query, true),
    do: where(query, [s], is_nil(s.topic_id))

  defp maybe_filter_nil_topic_id(query, false),
    do: where(query, [s], not is_nil(s.topic_id))

  defp maybe_filter_nil_topic_id(query, _), do: query

  defp maybe_filter_embedded(query, nil), do: query

  defp maybe_filter_embedded(query, true),
    do: join(query, :inner, [s], e in assoc(s, :embedding))

  defp maybe_filter_embedded(query, false),
    do:
      join(query, :full, [s], e in assoc(s, :embedding), as: :embedding)
      |> where([embedding: e], is_nil(e))

  defp maybe_filter_by_not_summarizer_id(query, nil), do: query

  defp maybe_filter_by_not_summarizer_id(query, summarizer_id) do
    query
    |> join(:left, [s], sum in assoc(s, :summaries), as: :sum)
    |> join(:left, [sum: s], cs in assoc(s, :conversation_summarizer), as: :con_sum)
    |> where([con_sum: cs], cs.summarizer_id != ^summarizer_id or is_nil(cs.summarizer_id))
  end

  defp maybe_filter_by_before(query, nil), do: query
  defp maybe_filter_by_before(query, before), do: where(query, [s], s.occurred_at < ^before)
  defp maybe_order_by_occurred_at(query, nil), do: query
  defp maybe_order_by_occurred_at(query, :desc), do: order_by(query, [s], desc: s.occurred_at)
  defp maybe_order_by_occurred_at(query, :asc), do: order_by(query, [s], asc: s.occurred_at)
  defp maybe_order_by_representative(query, nil), do: query

  defp maybe_order_by_representative(query, :desc),
    do: order_by(query, [s], desc: s.representative)

  defp maybe_limit(query, nil), do: query
  defp maybe_limit(query, limit), do: limit(query, [s], ^limit)
  defp maybe_offset(query, nil), do: query
  defp maybe_offset(query, offset), do: offset(query, [s], ^offset)
  defp maybe_filter_cumulative_content_length(query, nil), do: query

  defp maybe_filter_cumulative_content_length(query, content_length) do
    cumulative_length_query =
      select(query, [s], %{
        s
        | cumulative_length:
            over(sum(fragment("length(?)", s.content)), order_by: [desc: :representative])
      })

    from s in subquery(cumulative_length_query), where: s.cumulative_length < ^content_length
  end

  defp handle_query(query, true), do: Repo.aggregate(query, :count, :id)
  defp handle_query(query, _), do: Repo.all(query)

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
