defmodule DiscussitWeb.ConversationSummarizerLive.Show do
  use DiscussitWeb, :live_view

  alias Discussit.ConversationSummarizers
  alias Discussit.Summaries

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket, layout: {DiscussitWeb.Layouts, :full_screen}}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    conversation_summarizer =
      ConversationSummarizers.get_conversation_summarizer!(id, preloads: [:summarizer, :summaries])

    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:conversation_summarizer, conversation_summarizer)}
  end

  @impl true
  def handle_event("delete-summary", %{"id" => id}, socket) do
    Summaries.get_summary!(id)
    |> Summaries.delete_summary()

    conversation_summarizer =
      ConversationSummarizers.get_conversation_summarizer!(
        socket.assigns.conversation_summarizer.id,
        preloads: [:summarizer, :summaries]
      )

    {:noreply,
     socket
     |> assign(:conversation_summarizer, conversation_summarizer)}
  end

  defp page_title(:show), do: "Conversation Summary"

  defp format_date_time(dt), do: Calendar.strftime(dt, "%y-%m-%d %I:%M")
end
