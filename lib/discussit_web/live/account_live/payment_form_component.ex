defmodule DiscussitWeb.AccountLive.PaymentFormComponent do
  use DiscussitWeb, :live_component
  require Logger
  alias Discussit.Accounts

  @impl true
  def render(assigns) do
    ~H"""
    <div id={@id} class="flex flex-col">
      <.header>
        <%= @title %>
        <:subtitle>
          <%= @subtitle %>
        </:subtitle>
      </.header>
      <form
        action="#"
        method="post"
        data-secret={@intent.client_secret}
        data-account-id={@account.id}
        phx-hook="PaymentSetup"
        id="payment-form"
        class="flex-grow"
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

    setup_intent =
      case Stripe.SetupIntent.create(%{customer: id}) do
        {:ok, setup_intent} -> setup_intent
        {:error, _} -> %Stripe.SetupIntent{client_secret: nil}
      end

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:attrs, %{})
     |> assign(:intent, setup_intent)
     |> assign_form(changeset)}
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

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end
end
