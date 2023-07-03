defmodule OpenphoneRecorder.ConversationSummarizers do
  @moduledoc """
  The ConversationSummarizers context.
  """

  import Ecto.Query, warn: false
  alias OpenphoneRecorder.Repo

  alias OpenphoneRecorder.ConversationSummarizers.ConversationSummarizer

  def list_conversation_summaries do
    Repo.all(ConversationSummarizer)
  end

  def get_conversation_summarizer!(id), do: Repo.get!(ConversationSummarizer, id)

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
end
