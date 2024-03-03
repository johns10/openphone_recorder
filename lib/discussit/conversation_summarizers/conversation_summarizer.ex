defmodule Discussit.ConversationSummarizers.ConversationSummarizer do
  use Ecto.Schema
  import Ecto.Changeset
  alias Discussit.Summaries.Summary
  alias Discussit.Conversations.Conversation
  alias Discussit.Summarizers.Summarizer

  schema "conversation_summarizers" do
    belongs_to :conversation, Conversation, type: :binary_id
    belongs_to :summarizer, Summarizer

    has_many :summaries, Summary

    timestamps(type: :naive_datetime_usec)
  end

  @doc false
  def changeset(conversation_summarizer, attrs) do
    conversation_summarizer
    |> cast(attrs, [:conversation_id, :summarizer_id])
    |> foreign_key_constraint(:conversation_id)
    |> foreign_key_constraint(:summarizer_id)
    |> validate_required([:conversation_id, :summarizer_id])
  end
end
