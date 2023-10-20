defmodule DiscussitWeb.AccountLive.Form do
  use DiscussitWeb, :live_view

  alias Discussit.Accounts.Account

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:account, %Account{account_users: []})
     |> assign(:page_title, "New Account"), layout: {DiscussitWeb.Layouts, :full_screen}}
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
end
