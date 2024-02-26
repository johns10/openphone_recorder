defmodule Discussit.ConversationSummarizerPlans.ConversationSummarizerPlan do
  use Ecto.Schema
  import Ecto.Changeset

  schema "conversation_summarizer_plans" do
    field :name, :string

    timestamps()
  end

  @doc false
  def changeset(conversation_summarizer_plan, attrs) do
    conversation_summarizer_plan
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end
end
