defmodule DiscussitWeb.IndexLive.Index do
  use DiscussitWeb, :html_helpers

  use Phoenix.LiveView,
    container: {:div, class: "h-full flex-grow flex flex-col overflow-hidden"}

  on_mount({DiscussitWeb.UserAuth, :mount_current_user})

  import DiscussitWeb.IndexLive.Components

  alias Discussit.Conversations
  alias Discussit.Statements
  alias Discussit.Participants

  @impl true
  def mount(_params, _session, socket) do
    conversations =
      socket.assigns.user_setting.selected_account_id
      |> Conversations.list_conversation_summary()

    {:ok,
     socket
     |> assign(:conversation, nil)
     |> stream(:conversations, conversations)
     |> stream(:statements, []), layout: {DiscussitWeb.Layouts, :full_screen}}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  @impl true
  def handle_event(
        "set-participant-contact",
        %{"contact-id" => contact_id, "participant-id" => participant_id},
        socket
      ) do
    Participants.get_participant!(participant_id)
    |> Participants.update_participant(%{contact_id: contact_id})
    |> case do
      {:ok, _participant} ->
        %{assigns: %{conversation: conversation}} =
          socket = replace_statements(socket, socket.assigns.conversation.id)

        {:noreply, stream_insert(socket, :conversations, conversation)}

      _ ->
        {:noreply, socket}
    end
  end

  defp apply_action(socket, :index, %{"id" => conversation_id}) do
    replace_statements(socket, conversation_id)
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Conversations")
    |> assign(:conversation, nil)
  end

  @impl true
  def handle_info({_, {:account_picked, user_setting}}, socket) do
    conversations =
      user_setting.selected_account_id
      |> Conversations.list_conversation_summary()

    {:noreply,
     socket
     |> replace_conversations(conversations)
     |> assign(:user_setting, user_setting)
     |> push_patch(to: ~p"/home")}
  end

  defp replace_conversations(socket, conversations) do
    socket =
      Enum.reduce(socket.assigns.streams.conversations, socket, fn conversation, acc ->
        stream_delete(acc, :conversations, conversation)
      end)

    Enum.reduce(conversations, socket, fn conversation, acc ->
      stream_insert(acc, :conversations, conversation)
    end)
  end

  defp replace_statements(socket, conversation_id) do
    user = socket.assigns.current_user

    conversation =
      Conversations.get_conversation_summary!(
        conversation_id,
        socket.assigns.user_setting.selected_account_id
      )

    case Bodyguard.permit(Conversations, :get_conversation!, user, conversation) do
      :ok ->
        statements =
          Statements.list_statements(
            filters: [conversation_id: conversation_id],
            order_by: [occurred_at: :desc]
          )

        socket
        |> assign(:participant_sides, participant_sides(conversation.participants))
        |> assign(:page_title, "Listing Conversations")
        |> assign(:conversation, conversation)
        |> stream(:statements, statements, reset: true)

      {:error, :unauthorized} ->
        socket
        |> push_patch(to: ~p"/home")
        |> put_flash(:error, "You cannot access this conversation")
    end
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
