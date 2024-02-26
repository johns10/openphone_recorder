defmodule Discussit.ConversationSummarizers do
  @moduledoc """
  The ConversationSummarizers context.
  """

  import Ecto.Query, warn: false
  alias Discussit.Repo

  alias Discussit.ConversationSummarizers.ConversationSummarizer

  def list_conversation_summarizers(opts \\ []) do
    filters = Keyword.get(opts, :filters, [])
    preloads = Keyword.get(opts, :preloads, [])

    ConversationSummarizer
    |> maybe_filter_by_conversation_id(filters[:conversation_id])
    |> maybe_filter_by_summarizer_id(filters[:summarizer_id])
    |> filter_by_conversation_summarizer_plan_id(filters[:conversation_summarizer_plan_id])
    |> preload(^preloads)
    |> Repo.all()
  end

  def get_conversation_summarizer!(id, opts \\ []) do
    preloads = Keyword.get(opts, :preloads, [])

    ConversationSummarizer
    |> preload(^preloads)
    |> Repo.get!(id)
  end

  def get_conversation_summarizer_by(filters \\ [], opts \\ []) do
    preloads = Keyword.get(opts, :preloads, [])

    ConversationSummarizer
    |> preload(^preloads)
    |> Repo.get_by(filters)
  end

  def create_conversation_summarizer(attrs \\ %{}) do
    %ConversationSummarizer{}
    |> ConversationSummarizer.changeset(attrs)
    |> Repo.insert()
  end

  def update_conversation_summarizer(%ConversationSummarizer{} = conversation_summarizer, attrs) do
    conversation_summarizer
    |> ConversationSummarizer.changeset(attrs)
    |> Repo.update()
  end

  def upsert_conversation_summarizer(attrs \\ %{}) do
    case get_conversation_summarizer_by(Map.take(attrs, [:conversation_id, :summarizer_id])) do
      nil -> create_conversation_summarizer(attrs)
      conversation_summarizer -> {:ok, conversation_summarizer}
    end
    |> case do
      {:ok, conversation_summarizer} ->
        update_conversation_summarizer(
          conversation_summarizer,
          Map.drop(attrs, [:conversation_id, :summarizer_id])
        )

      other ->
        other
    end
  end

  def delete_conversation_summarizer(%ConversationSummarizer{} = conversation_summarizer) do
    Repo.delete(conversation_summarizer)
  end

  def change_conversation_summarizer(
        %ConversationSummarizer{} = conversation_summarizer,
        attrs \\ %{}
      ) do
    ConversationSummarizer.changeset(conversation_summarizer, attrs)
  end

  defp maybe_filter_by_conversation_id(query, nil), do: query

  defp maybe_filter_by_conversation_id(query, conversation_id),
    do: where(query, [s], s.conversation_id == ^conversation_id)

  defp maybe_filter_by_summarizer_id(query, nil), do: query

  defp maybe_filter_by_summarizer_id(query, summarizer_id),
    do: where(query, [s], s.summarizer_id == ^summarizer_id)

  defp filter_by_conversation_summarizer_plan_id(query, nil), do: query

  defp filter_by_conversation_summarizer_plan_id(query, conversation_summarizer_plan),
    do: where(query, [s], s.conversation_summarizer_plan == ^conversation_summarizer_plan)
end
