defmodule OpenphoneRecorderWeb.IndexLive.Index do
  use OpenphoneRecorderWeb, :html_helpers

  use Phoenix.LiveView,
    container: {:div, class: "h-full flex-grow flex flex-col overflow-hidden"}

  import OpenphoneRecorderWeb.IndexLive.Components

  alias OpenphoneRecorder.Conversations
  alias OpenphoneRecorder.Statements
  alias OpenphoneRecorder.ConversationSummarizers

  @default_preloads [:participants, [participants: [phone_number: :contact]]]

  @impl true
  @spec mount(any, any, Phoenix.LiveView.Socket.t()) ::
          {:ok, Phoenix.LiveView.Socket.t(), [{:layout, {any, any}}, ...]}
  def mount(_params, _session, socket) do
    conversations = Conversations.list_conversation_summary()

    {:ok,
     socket
     |> assign(:zoom_level, 0)
     |> assign(:summaries, [])
     |> assign(:conversations, conversations)
     |> assign(:statements, []), layout: {OpenphoneRecorderWeb.Layouts, :full_screen}}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  @impl true
  def handle_event("summarize", _, socket) do
    attrs = [filters: [conversation_id: socket.assigns.conversation.id, summarizer_id: 1]]
    conversation = socket.assigns.conversation
    summarizer = OpenphoneRecorder.Summarizers.get_summarizer!(1)

    conversation_summarizer =
      attrs
      |> ConversationSummarizers.get_conversation_summarizer_by()
      |> case do
        nil ->
          {:ok, cs} =
            ConversationSummarizers.create_conversation_summarizer(%{
              conversation_id: socket.assigns.conversation.id,
              summarizer_id: 1
            })

          cs

        cs ->
          cs
      end
      |> Map.put(:summarizer, summarizer)
      |> Map.put(:conversation, conversation)

    opts = [time_zone: "Etc/UTC"]

    Task.start(fn ->
      OpenphoneRecorder.ConversationSummarizer.create_daily_summaries(
        conversation_summarizer,
        ,
        opts
      )
    end)

    {:noreply, socket}
  end

  @impl true
  def handle_event("zoom_out", _, socket) do
    conversation_id = socket.assigns.conversation.id

    summaries =
      OpenphoneRecorder.Summaries.list_summaries(
        filters: [
          conversation_id: conversation_id,
          level: OpenphoneRecorder.Summaries.Summary.daily()
        ]
      )

    {:noreply,
     socket
     |> assign(:summaries, summaries)
     |> assign(:zoom_level, OpenphoneRecorder.Summaries.Summary.daily())}
  end

  def handle_event("zoom_in", _, socket) do
    {:noreply,
     socket
     |> assign(:zoom_level, 0)}
  end

  defp apply_action(socket, :index, %{"conversation_id" => conversation_id}) do
    conversation = Conversations.get_conversation!(conversation_id, preloads: @default_preloads)

    statements =
      Statements.list_statements(
        filters: [conversation_id: conversation_id],
        order_by: [occurred_at: :desc]
      )

    socket
    |> assign(:statements, statements)
    |> assign(:participant_sides, participant_sides(conversation.participants))
    |> assign(:page_title, "Listing Conversations")
    |> assign(:conversation, conversation)
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Conversations")
    |> assign(:conversation, nil)
  end

  defp participant_sides([p1, p2 | tail]) do
    [
      {atomize(p1.id), "chat-start"},
      {atomize(p2.id), "chat-end"}
      | Enum.map(tail, &{atomize(&1.id), "chat-end"})
    ]
  end

  defp atomize(int), do: :"#{int}"
end
