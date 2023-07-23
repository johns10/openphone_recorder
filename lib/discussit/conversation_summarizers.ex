defmodule Discussit.ConversationSummarizers do
  @moduledoc """
  The ConversationSummarizers context.
  """

  import Ecto.Query, warn: false
  alias Discussit.Repo

  alias Discussit.ConversationSummarizers.ConversationSummarizer

  def list_conversation_summaries(opts \\ []) do
    filters = Keyword.get(opts, :filters, [])

    ConversationSummarizer
    |> maybe_filter_by_conversation_id(filters[:conversation_id])
    |> maybe_filter_by_summarizer_id(filters[:summarizer_id])
    |> Repo.all()
  end

  def get_conversation_summarizer!(id), do: Repo.get!(ConversationSummarizer, id)

  def get_conversation_summarizer_by(opts \\ []) do
    filters =
      Keyword.get(opts, :filters, [])
      |> IO.inspect()

    ConversationSummarizer
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
end
