defmodule Discussit.ConversationSummarizerPlans do
  import Ecto.Query, warn: false
  alias Discussit.Repo

  alias Discussit.ConversationSummarizerPlans.ConversationSummarizerPlan

  def list_conversation_summarizer_plans(opts \\ []) do
    filters = Keyword.get(opts, :filters, [])
    preloads = Keyword.get(opts, :preloads, [])

    ConversationSummarizerPlan
    |> maybe_filter_by_conversation_id(filters[:conversation_id])
    |> Repo.all()
  end

  def get_conversation_summarizer_plan!(id), do: Repo.get!(ConversationSummarizerPlan, id)

  def create_conversation_summarizer_plan(attrs \\ %{}) do
    %ConversationSummarizerPlan{}
    |> ConversationSummarizerPlan.changeset(attrs)
    |> Repo.insert()
  end

  def update_conversation_summarizer_plan(
        %ConversationSummarizerPlan{} = conversation_summarizer_plan,
        attrs
      ) do
    conversation_summarizer_plan
    |> ConversationSummarizerPlan.changeset(attrs)
    |> Repo.update()
  end

  def delete_conversation_summarizer_plan(
        %ConversationSummarizerPlan{} = conversation_summarizer_plan
      ) do
    Repo.delete(conversation_summarizer_plan)
  end

  def change_conversation_summarizer_plan(
        %ConversationSummarizerPlan{} = conversation_summarizer_plan,
        attrs \\ %{}
      ) do
    ConversationSummarizerPlan.changeset(conversation_summarizer_plan, attrs)
  end

  defp maybe_filter_by_conversation_id(query, nil), do: query

  defp maybe_filter_by_conversation_id(query, conversation_id),
    do: where(query, [s], s.conversation_id == ^conversation_id)
end
