defmodule DiscussitWeb.CreditLive.Show do
  use DiscussitWeb, :live_view

  alias Discussit.Credits

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:credit, Credits.get_credit!(id))}
  end

  defp page_title(:show), do: "Show Credit"
  defp page_title(:edit), do: "Edit Credit"
end
