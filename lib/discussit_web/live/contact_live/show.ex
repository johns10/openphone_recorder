defmodule DiscussitWeb.ContactLive.Show do
  use DiscussitWeb, :live_view

  alias Discussit.Contacts

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    contact = Contacts.get_contact!(id, preloads: [contact_phone_numbers: :phone_number])

    case Bodyguard.permit(Contacts, :get_contact!, socket.assigns.current_user, contact) do
      :ok ->
        {:noreply,
         socket
         |> assign(:page_title, page_title(socket.assigns.live_action))
         |> assign(:contact, contact)}

      {:error, :unauthorized} ->
        {:noreply,
         socket
         |> push_navigate(to: ~p"/home")
         |> put_flash(:error, "You cannot access this contact")}
    end
  end

  defp page_title(:show), do: "Show Contact"
  defp page_title(:edit), do: "Edit Contact"
end
