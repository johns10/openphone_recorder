defmodule OpenphoneRecorderWeb.ContactLive.Index do
  use OpenphoneRecorderWeb, :live_view

  alias OpenphoneRecorder.Contacts
  alias OpenphoneRecorder.Contacts.Contact

  @impl true
  def mount(_params, _session, socket) do
    contacts =
      case socket.assigns.user_setting.selected_account_id do
        nil -> []
        account_id -> Contacts.list_contacts(filters: [account_id: account_id])
      end

    {:ok, stream(socket, :contacts, contacts)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    contact = Contacts.get_contact!(id)

    case Bodyguard.permit(Contacts, :get_contact!, socket.assigns.current_user, contact) do
      :ok ->
        socket
        |> assign(:page_title, "Edit Contact")
        |> assign(:contact, contact)

      :error ->
        socket
        |> push_patch(to: ~p"/home")
        |> put_flash(:error, "You cannot access this account")
    end
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Contact")
    |> assign(:contact, %Contact{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Contacts")
    |> assign(:contact, nil)
  end

  @impl true
  def handle_info({OpenphoneRecorderWeb.ContactLive.FormComponent, {:saved, contact}}, socket) do
    {:noreply, stream_insert(socket, :contacts, contact)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    contact = Contacts.get_contact!(id)
    {:ok, _} = Contacts.delete_contact(contact)

    {:noreply, stream_delete(socket, :contacts, contact)}
  end
end
