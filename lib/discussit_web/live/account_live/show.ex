defmodule DiscussitWeb.AccountLive.Show do
  use DiscussitWeb, :live_view
  require Logger
  alias Discussit.Accounts

  @preloads [:billing_user, account_users: :user]

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
  def handle_info({_, {:saved, account}}, socket) do
    {:noreply, assign(socket, :account, Discussit.Repo.preload(account, @preloads))}
  end

  def handle_info({_, {:new_account_user, account_user}}, socket) do
    account = socket.assigns.account
    account = Map.put(account, :account_users, account.account_users ++ [account_user])
    {:noreply, assign(socket, :account, account)}
  end

  def handle_event("default-payment-method", %{"id" => id}, socket) do
    with {:ok, _customer} <-
           Stripe.Customer.update(socket.assigns.account.stripe_customer_id, %{
             invoice_settings: %{default_payment_method: id}
           }),
         {:ok, account} <-
           Accounts.update_account(socket.assigns.account, %{
             default_payment_method_id: id
           }) do
      {:noreply,
       socket
       |> assign(:account, account)
       |> push_patch(to: "/accounts/#{socket.assigns.account.id}")}
    else
      {:error, %Stripe.Error{message: message}} ->
        Logger.error(message)
        {:noreply, socket}
    end
  end

  defp render_sensitive_string(nil), do: nil

  defp render_sensitive_string(secret) when is_binary(secret) do
    "*#{String.slice(secret, -4..-1)}"
  end

  defp page_title(:show), do: "Show Account"
  defp page_title(:edit), do: "Edit Account"
  defp page_title(:add_payment), do: "Add Payment Info"
end
