defmodule DiscussitWeb.ContactLive.Index do
  use DiscussitWeb, :live_view

  alias Discussit.Contacts
  alias Discussit.Contacts.Contact

  @preloads [contact_phone_numbers: :phone_number]

  @impl true
  def mount(_params, _session, socket) do
    contacts =
      case socket.assigns.current_user.selected_account_id do
        nil -> []
        account_id -> Contacts.list_contacts(filters: [account_id: account_id], limit: 20)
      end

    {:ok,
     socket
     |> stream(:contacts, contacts)
     |> assign(per_page: 20, page: 1, attrs: %{}, contact: nil, end_of_timeline?: false),
     layout: {DiscussitWeb.Layouts, :full_screen}}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :show, %{"id" => id}) do
    contact = Contacts.get_contact!(id, preloads: @preloads)

    case Bodyguard.permit(Contacts, :get_contact!, socket.assigns.current_user, contact) do
      :ok ->
        socket
        |> assign(:page_title, "Show Contact")
        |> assign(:contact, contact)

      {:error, :unauthorized} ->
        socket
        |> push_navigate(to: ~p"/home")
        |> put_flash(:error, "You cannot access this contact")
    end
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    contact = Contacts.get_contact!(id, preloads: @preloads)

    case Bodyguard.permit(Contacts, :get_contact!, socket.assigns.current_user, contact) do
      :ok ->
        socket
        |> assign(:page_title, "Edit Contact")
        |> assign(:contact, contact)

      {:error, :unauthorized} ->
        socket
        |> push_navigate(to: ~p"/home")
        |> put_flash(:error, "You cannot access this contact")
    end
  end

  defp apply_action(socket, :new, params) do
    attrs = Map.take(params, ["phone_number"])

    socket
    |> assign(:page_title, "New Contact")
    |> assign(:contact, %Contact{contact_phone_numbers: []})
    |> assign(:attrs, attrs)
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Contacts")
    |> assign(:contact, nil)
  end

  @impl true
  def handle_info({DiscussitWeb.ContactLive.FormComponent, {:saved, contact}}, socket) do
    {:noreply, stream_insert(socket, :contacts, contact)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    contact = Contacts.get_contact!(id)
    {:ok, _} = Contacts.delete_contact(contact)

    {:noreply, stream_delete(socket, :contacts, contact)}
  end

  def handle_event("next-page", _, socket) do
    {:noreply, append(socket, socket.assigns.page + 1)}
  end

  defp append(socket, new_page) when new_page >= 1 do
    %{per_page: per_page} = socket.assigns

    contacts =
      Contacts.list_contacts(
        filters: [account_id: socket.assigns.current_user.selected_account_id],
        offset: (new_page - 1) * per_page,
        limit: per_page
      )

    case contacts do
      [] ->
        assign(socket, end_of_timeline?: true)

      [_ | _] = contacts ->
        socket
        |> assign(end_of_timeline?: false)
        |> assign(:page, new_page)
        |> stream(:contacts, contacts, at: -1)
    end
  end
end
