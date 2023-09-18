defmodule DiscussitWeb.AccountLive.PaymentFormComponent do
  use DiscussitWeb, :live_component
  require Logger
  alias Discussit.Accounts
  alias Discussit.AccountUsers

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
          <div id="card-element" class="tag-input"></div>
          <div id="card-errors" class="tag-label" role="alert"></div>
        </div>

        <button class="btn btn-success w-full">Add Card</button>
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
  def handle_event("validate", %{"account" => account_params}, socket) do
    changeset =
      socket.assigns.account
      |> Accounts.change_account(account_params)
      |> Map.put(:action, :validate)

    {:noreply, socket |> assign_form(changeset) |> assign(:attrs, account_params)}
  end

  def handle_event("save", %{"account" => account_params}, socket) do
    save_account(socket, socket.assigns.action, account_params)
  end

  def handle_event("reset-timezone", _, socket) do
    changeset =
      socket.assigns.form.source
      |> Ecto.Changeset.put_change(:timezone, "")

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("delete-account-user", %{"id" => id}, socket) do
    account_user = AccountUsers.get_account_user!(id)
    {:ok, _} = AccountUsers.delete_account_user(account_user)
    account = socket.assigns.account
    account_users = account.account_users |> Enum.reject(&(&1.id == account_user.id))
    account = Map.put(account, :account_users, account_users)

    {:noreply, assign(socket, :account, account)}
  end

  defp save_account(socket, :edit, account_params) do
    with {:ok, %{stripe_customer_id: id, name: name, billing_user_id: user_id} = account} <-
           Accounts.update_account(socket.assigns.account, account_params),
         %{email: email} <- Discussit.Users.get_user!(user_id),
         {:ok, _customer} <- Stripe.Customer.update(id, %{email: email, name: name}) do
      notify_parent({:saved, account})

      case {Map.get(socket.assigns, :patch, nil), Map.get(socket.assigns, :redirect, nil)} do
        {patch, nil} ->
          {:noreply,
           socket
           |> put_flash(:info, "Account updated successfully")
           |> push_patch(to: patch)}

        {nil, redirect} ->
          {:noreply,
           socket
           |> put_flash(:info, "Account updated successfully")
           |> redirect(to: redirect)}
      end
    else
      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}

      {:error, %Stripe.Error{message: message}} ->
        Logger.error("Stripe error in #{__MODULE__}, message: #{message}")
        {:noreply, socket}
    end
  end

  defp save_account(socket, :new, account_params) do
    with {:ok, %{name: name} = account} <- Accounts.create_account(account_params),
         {:ok, _account_user} <-
           AccountUsers.create_account_user(%{
             account_id: account.id,
             user_id: socket.assigns.current_user.id
           }),
         %{email: email} <- Discussit.Users.get_user!(account.billing_user_id),
         {:ok, %{id: id}} <- Stripe.Customer.create(%{email: email, name: name}),
         {:ok, account} <- Accounts.update_account(account, %{stripe_customer_id: id}) do
      notify_parent({:saved, account})

      case {Map.get(socket.assigns, :patch, nil), Map.get(socket.assigns, :redirect, nil)} do
        {patch, nil} ->
          {:noreply,
           socket
           |> put_flash(:info, "Account created successfully")
           |> push_patch(to: patch)}

        {nil, redirect} ->
          {:noreply,
           socket
           |> put_flash(:info, "Account created successfully")
           |> redirect(to: redirect)}
      end
    else
      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}

      {:error, %Stripe.Error{message: message}} ->
        Logger.error("Stripe error in #{__MODULE__}, message: #{message}")
        {:noreply, socket}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
