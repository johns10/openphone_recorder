defmodule DiscussitWeb.AccountLive.Show do
  use DiscussitWeb, :live_view

  alias Discussit.Accounts
  alias Discussit.AccountUsers

  @preloads [account_users: :user]

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    account = Accounts.get_account!(id, preloads: @preloads)

    case Bodyguard.permit(Accounts, :get_account!, socket.assigns.current_user, id) do
      :ok ->
        {:noreply,
         socket
         |> assign(:page_title, page_title(socket.assigns.live_action))
         |> assign(:account, account)}

      {:error, _} ->
        {:noreply,
         socket
         |> push_patch(to: ~p"/home")
         |> put_flash(:error, "You cannot access this account")}
    end
  end

  @impl true
  def handle_event("delete-account-user", %{"id" => id}, socket) do
    account_user = AccountUsers.get_account_user!(id)
    {:ok, _} = AccountUsers.delete_account_user(account_user)
    account = socket.assigns.account
    account_users = account.account_users |> Enum.reject(&(&1.id == account_user.id))
    account = Map.put(account, :account_users, account_users)

    {:noreply, assign(socket, :account, account)}
  end

  @impl true
  def handle_info({_, {:new_account_user, account_user}}, socket) do
    account = socket.assigns.account
    account = Map.put(account, :account_users, account.account_users ++ [account_user])
    {:noreply, assign(socket, :account, account)}
  end

  def handle_info({_, {:saved, account}}, socket) do
    {:noreply, assign(socket, :account, account)}
  end

  defp render_signing_secret(nil), do: nil

  defp render_signing_secret(secret) when is_binary(secret) do
    "*#{String.slice(secret, -4..-1)}"
  end

  defp page_title(:show), do: "Show Account"
  defp page_title(:edit), do: "Edit Account"
end
