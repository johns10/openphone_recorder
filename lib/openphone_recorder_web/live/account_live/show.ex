defmodule OpenphoneRecorderWeb.AccountLive.Show do
  use OpenphoneRecorderWeb, :live_view

  alias OpenphoneRecorder.Accounts
  alias OpenphoneRecorder.AccountUsers

  @preloads [account_users: :user]

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:account, Accounts.get_account!(id, preloads: @preloads))}
  end

  @impl true
  def handle_event("delete-account-user", %{"id" => id}, socket) do
    account_user = AccountUsers.get_account_user!(id)
    {:ok, _} = AccountUsers.delete_account_user(account_user)
    account = socket.assigns.account
    account_users = account.account_users |> Enum.reject(& &1.id == account_user.id)
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

  defp page_title(:show), do: "Show Account"
  defp page_title(:edit), do: "Edit Account"
end
