defmodule DiscussitWeb.AccountLive.FormComponent do
  use DiscussitWeb, :live_component
  require Logger
  alias Discussit.Accounts
  alias Discussit.AccountUsers
  import DiscussitWeb.LiveSupport

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
      </.header>

      <.simple_form
        for={@form}
        id="account-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:name]} type="text" label="Name" />
        <.input field={@form[:openphone_signing_secret]} type="text" label="Signing Secret" />
        <.input field={@form[:openai_api_key]} type="text" label="OpenAI API Key" />
        <.input
          field={@form[:billing_user_id]}
          type="select"
          label="Billing User"
          options={
            if @account.id,
              do: select_options(Discussit.Users.list_users(@account.id)),
              else: select_options([@current_user])
          }
          selected={@current_user.id}
        />

        <.input
          field={@form[:plan]}
          type="select"
          label="Plan"
          prompt="Choose a value"
          options={Ecto.Enum.values(Discussit.Accounts.Account, :plan)}
        />
        <:actions>
          <.button class="btn-success" phx-disable-with="Saving...">Save Account</.button>
        </:actions>
      </.simple_form>

      <.header class="pt-4">Account Users</.header>

      <.table class="!mb-0" id="account_users" rows={@account.account_users}>
        <:col :let={account_user} label="Email"><%= account_user.user.email %></:col>
        <:action :let={account_user}>
          <.link phx-click="delete-account-user" phx-value-id={account_user.id} phx-target={@myself}>
            Remove
          </.link>
        </:action>
      </.table>

      <.live_component
        module={DiscussitWeb.AccountUserLive.FormComponent}
        id="account-user-form"
        account_id={@account.id}
        patch={@patch}
        current_user={@current_user}
        account_user={%Discussit.AccountUsers.AccountUser{}}
      />

      <.header class="my-4">Payment Methods</.header>

      <.live_component
        id={@account.id}
        module={DiscussitWeb.AccountLive.PaymentMethodsComponent}
        account={@account}
      />

      <.link patch={@patch <> "/add_payment"}>
        <.button class="btn-primary my-4">Add Payment Method</.button>
      </.link>

      <.modal :if={@action == :add_payment} id="payment-modal" show on_cancel={JS.patch(@patch)}>
        <.live_component
          module={DiscussitWeb.AccountLive.PaymentFormComponent}
          id={"#{@account.id}"}
          account={@account}
          patch={@patch}
          current_user={@current_user}
          title="Add a Credit Card to Your Account"
          subtitle=""
        />
      </.modal>
    </div>
    """
  end

  @impl true
  def update(%{account: account} = assigns, socket) do
    changeset = Accounts.change_account(account)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:attrs, %{})
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

      nil ->
        {:noreply, socket}

      {:error, %{message: message}} ->
        Logger.error("#{__MODULE__} #{message}")
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

      nil ->
        {:noreply, socket}

      {:error, %{message: message}} ->
        Logger.error("#{__MODULE__} #{message}")
        {:noreply, socket}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
