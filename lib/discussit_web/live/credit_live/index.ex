defmodule DiscussitWeb.CreditLive.Index do
  use DiscussitWeb, :live_view

  alias Discussit.Credits
  alias Discussit.Credits.Credit

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :credits, Credits.list_credits()),
     layout: {DiscussitWeb.Layouts, :full_screen}}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Credit")
    |> assign(:credit, Credits.get_credit!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Credit")
    |> assign(:credit, %Credit{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Credits")
    |> assign(:credit, nil)
  end

  @impl true
  def handle_info({DiscussitWeb.CreditLive.FormComponent, {:saved, credit}}, socket) do
    {:noreply, stream_insert(socket, :credits, credit)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    credit = Credits.get_credit!(id)
    {:ok, _} = Credits.delete_credit(credit)

    {:noreply, stream_delete(socket, :credits, credit)}
  end
end
