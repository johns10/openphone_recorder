defmodule DiscussitWeb.AccountLive.PaymentMethodsComponent do
  use DiscussitWeb, :live_component
  require Logger
  alias Discussit.Accounts

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <div class="my-4">
        <.header>Payment Methods</.header>
      </div>

      <div :if={@default} class="flex flex-row">
        <.button class="rounded-r-none btn-success">
          <.icon name="hero-check-circle" />
        </.button>
        <div class="bg-success flex flex-row py-2 px-4 items-center space-x-8">
          <div>
            <p class="font-medium tracking-more-wider text-secondary-content">
              <%= "****  ****  ****  #{@default.card.last4}" %>
            </p>
          </div>
          <div>
            <p class="font-medium tracking-wider text-secondary-content">
              <%= @default.card.exp_month %>/<%= @default.card.exp_year %>
            </p>
          </div>
        </div>
        <.button
          phx-click="remove-card"
          phx-value-id={@default.id}
          class="rounded-l-none btn-error"
          disabled
        >
          <.icon name="hero-trash" />
        </.button>
      </div>

      <div :if={length(@payment_methods) > 0} class="flex flex-col space-y-4 my-4">
        <div :for={method <- @payment_methods} class="flex flex-row">
          <.button
            class="rounded-r-none btn-success"
            phx-click="default-payment-method"
            phx-value-id={method.id}
          >
            <.icon name="hero-check-circle" />
          </.button>
          <div class="bg-secondary flex flex-row py-2 px-4 items-center space-x-8">
            <div>
              <p class="font-medium tracking-more-wider text-secondary-content">
                <%= "****  ****  ****  #{method.card.last4}" %>
              </p>
            </div>
            <div>
              <p class="font-medium tracking-wider text-secondary-content">
                <%= method.card.exp_month %>/<%= method.card.exp_year %>
              </p>
            </div>
          </div>
          <.button phx-click="remove-card" phx-value-id={method.id} class="rounded-l-none btn-error">
            <.icon name="hero-trash" />
          </.button>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def update(%{account: account} = assigns, socket) do
    stripe_customer_id = Map.get(account, :stripe_customer_id, nil)
    billing_user_id = Map.get(account, :billing_user_id, nil)

    stripe_customer_id =
      if is_nil(stripe_customer_id) and not is_nil(billing_user_id) do
        with %{email: email} <- Discussit.Users.get_user!(billing_user_id),
             {:ok, %{id: id}} <- Sripe.Customer.create(%{email: email, name: account.name}),
             {:ok, _account} <- Accounts.update_account(account, %{stripe_customer_id: id}) do
          id
        end
      else
        stripe_customer_id
      end

    {default, payment_methods} =
      with {:ok, customer} <- Stripe.Customer.retrieve(stripe_customer_id),
           {:ok, %{data: methods}} <- Stripe.PaymentMethod.list(%{customer: customer}),
           {default, methods} <- find_default_method(customer, methods) do
        {default, methods}
      end

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:default, default)
     |> assign(:payment_methods, payment_methods)}
  end

  @impl true
  def handle_event("payment-setup", %{"payment_method" => payment_method}, socket) do
    with {:ok, customer} <- Stripe.Customer.retrieve(socket.assigns.account.stripe_customer_id),
         {:ok, _relationship} <-
           Stripe.PaymentMethod.attach(%{customer: customer, payment_method: payment_method}) do
      if !customer.invoice_settings.default_payment_method do
        with {:ok, _} <-
               Stripe.Customer.update(customer.id, %{
                 invoice_settings: %{default_payment_method: payment_method}
               }),
             {:ok, account} <-
               Accounts.update_account(socket.assigns.account, %{
                 default_payment_id: payment_method
               }) do
          {:ok, account}
        end
      end

      case socket.assigns do
        %{patch: patch} when not is_nil(patch) ->
          {:noreply, socket |> push_patch(to: socket.assigns.patch)}

        %{hide_modal: true} ->
          {:noreply, push_event(socket, "js-exec", %{to: "#paywall-modal", attr: "phx-remove"})}
      end
    else
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

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end
end
