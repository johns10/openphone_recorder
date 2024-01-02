defmodule Discussit.Topics do
  @moduledoc """
  The Topics context.
  """

  import Ecto.Query, warn: false
  alias Discussit.Repo

  alias Discussit.Topics.Topic

  def list_topics(opts \\ []) do
    filters = Keyword.get(opts, :filters, [])
    preload = Keyword.get(opts, :preload, [])

    Topic
    |> filter_by_account_id(filters[:account_id])
    |> filter_by_model_id(filters[:model_id])
    |> filter_by_title_is_nil(filters[:title_is_nil])
    |> search(filters[:search])
    |> maybe_limit(opts[:limit])
    |> preload(^preload)
    |> Repo.all()
  end

  def get_topic!(id, opts \\ []) do
    preload = Keyword.get(opts, :preload, [])

    Topic
    |> preload(^preload)
    |> Repo.get!(id)
  end

  def get_next_unmigrated_topic!(id, model_id) do
    Topic
    |> filter_by_model_id(model_id)
    |> join(:full, [t], to in assoc(t, :to_topic), as: :to)
    |> where([to: to], is_nil(to.from_topic_id))
    |> where([t], t.id != ^id)
    |> limit(1)
    |> Repo.all()
    |> case do
      [topic] -> topic
      _ -> nil
    end
  end

  def get_topic_by(filters \\ []) do
    Repo.get_by(Topic, filters)
  end

  defp filter_by_account_id(query, nil), do: query
  defp filter_by_account_id(query, account_id), do: where(query, [t], t.account_id == ^account_id)

  defp filter_by_model_id(query, nil), do: query
  defp filter_by_model_id(query, model_id), do: where(query, [t], t.model_id == ^model_id)

  defp filter_by_title_is_nil(query, nil), do: query
  defp filter_by_title_is_nil(query, _), do: where(query, [t], is_nil(t.title))

  defp search(query, nil), do: query

  defp search(query, text) do
    query
    |> where([t], ilike(t.title, ^"%#{text}%"))
    |> or_where([t], ilike(t.model_title, ^"%#{text}%"))
  end

  defp maybe_limit(query, nil), do: query
  defp maybe_limit(query, value), do: limit(query, ^value)

  def create_topic(attrs \\ %{}) do
    %Topic{}
    |> Topic.changeset(attrs)
    |> Repo.insert()
  end

  def update_topic(%Topic{} = topic, attrs) do
    topic
    |> Topic.changeset(attrs)
    |> Repo.update()
  end

  def delete_topic(%Topic{} = topic) do
    topic
    |> Topic.changeset(%{})
    |> Repo.delete()
  end

  def change_topic(%Topic{} = topic, attrs \\ %{}) do
    Topic.changeset(topic, attrs)
  end

  def summarize_topic(topic_id) do
    topic = get_topic!(topic_id)

    content =
      Discussit.Statements.list_statements(
        filter: [topic_id: topic_id],
        order_by: [cumulative_content_length: 3000, representative: :desc]
      )
      |> Enum.map(& &1.content)
      |> Enum.join(" ")

    """
    I have a topic that contains the following documents:
    #{content}
    The topic is described by the following keywords:
    #{Enum.map(topic.keywords, fn %{"keyword" => keyword} -> keyword end) |> Enum.join(", ")}

    Based on the information above:
    Extract a short but highly descriptive topic label of at most 5 words.
    Extract a short but highly descriptive topic description of at most 100 words
    Return the result in the following format
    <topic label> | <topic description>
    """
  end
end
