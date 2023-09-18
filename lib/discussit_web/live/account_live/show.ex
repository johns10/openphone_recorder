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
        {default, payment_methods} =
          with id when is_binary(id) <- Map.get(account, :stripe_customer_id, nil),
               {:ok, customer} <- Stripe.Customer.retrieve(id),
               {:ok, %{data: methods}} <- Stripe.PaymentMethod.list(%{customer: customer}),
               {default, methods} <- find_default_method(customer, methods) do
            {default, methods}
          else
            _ -> []
          end

        {:noreply,
         socket
         |> assign(:page_title, page_title(socket.assigns.live_action))
         |> assign(:account, account)
         |> assign(:payment_methods, payment_methods)
         |> assign(:default, default)}

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

  @impl true
  def handle_event("remove-card", %{"id" => id}, socket) do
    with {:ok, _} <- Stripe.PaymentMethod.detach(%{payment_method: id}) do
      {:noreply, socket |> push_patch(to: "/accounts/#{socket.assigns.account.id}")}
    end
  end

  def handle_event("default-payment-method", %{"id" => id}, socket) do
    case Stripe.Customer.update(socket.assigns.account.stripe_customer_id, %{
           invoice_settings: %{default_payment_method: id}
         }) do
      {:ok, _customer} ->
        {:noreply, socket |> push_patch(to: "/accounts/#{socket.assigns.account.id}")}

      {:error, %Stripe.Error{message: message}} ->
        Logger.error(message)
        {:noreply, socket}
    end
  end

  defp find_default_method(customer, payment_methods) do
    if customer.invoice_settings.default_payment_method do
      {Enum.find(
         payment_methods,
         &(&1.id == customer.invoice_settings.default_payment_method)
       ),
       Enum.reject(payment_methods, &(&1.id == customer.invoice_settings.default_payment_method))}
    else
      {nil, payment_methods}
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
