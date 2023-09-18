defmodule DiscussitWeb.AccountLive.PaymentFormComponent do
  use DiscussitWeb, :live_component
  require Logger
  alias Discussit.Accounts

  @impl true
  def render(assigns) do
    ~H"""
    <div id={@id}>
      <.header>
        Add a Credit Card to Your Account
      </.header>
      <form
        action="#"
        method="post"
        data-secret={@intent.client_secret}
        data-account-id={@account.id}
        phx-hook="PaymentSetup"
        id="payment-form"
      >
        <div class="my-4">
          <div id="payment-element" class="tag-input"></div>
          <div id="card-errors" class="tag-label" role="alert"></div>
        </div>

        <.button id="submit-payment" class="btn btn-success w-full">
          Add Card
        </.button>
      </form>
    </div>
    """
  end

  @impl true
  def update(%{account: %{stripe_customer_id: id} = account} = assigns, socket) do
    changeset = Accounts.change_account(account)
    {:ok, setup_intent} = Stripe.SetupIntent.create(%{customer: id})

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:attrs, %{})
     |> assign(:intent, setup_intent)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("payment-setup", %{"payment_method" => payment_method} = attrs, socket) do
    with {:ok, customer} <- Stripe.Customer.retrieve(socket.assigns.account.stripe_customer_id),
         {:ok, _relationship} <-
           Stripe.PaymentMethod.attach(%{customer: customer, payment_method: payment_method}) do
      if !customer.invoice_settings.default_payment_method do
        Stripe.Customer.update(customer.id, %{
          invoice_settings: %{default_payment_method: payment_method}
        })
      end

      {:noreply, socket |> push_patch(to: "/accounts/#{socket.assigns.account.id}")}
    else
      {:error, %Stripe.Error{message: message}} ->
        Logger.error(message)
        {:noreply, socket}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end
end
