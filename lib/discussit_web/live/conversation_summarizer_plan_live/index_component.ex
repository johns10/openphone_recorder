defmodule DiscussitWeb.ConversationSummarizerPlanLive.ShowComponent do
  use DiscussitWeb, :live_component
  import DiscussitWeb.IndexLive.Components
  alias Discussit.ConversationSummarizerPlans

  @impl true
  def update(%{conversation_id: conversation_id} = assigns, socket) do
    plans =
      ConversationSummarizerPlans.list_conversation_summarizer_plans(
        filters: [conversation_id: conversation_id]
      )

    {:ok,
     socket
     |> assign(assigns)
     |> stream(:plans, plans)}
  end
end
