defmodule DiscussitWeb.AccountLive.FormComponent do
  use DiscussitWeb, :live_component

  alias Discussit.Accounts
  alias Discussit.AccountUsers
  import DiscussitWeb.LiveSupport

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>Use this form to manage account records in your database.</:subtitle>
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
          prompt="Choose the user to communicate billing information to"
          options={if @account.id, do: select_options(Discussit.Users.list_users(@account.id)), else: select_options([@current_user])}
        />

        <.input
          field={@form[:plan]}
          type="select"
          label="Plan"
          prompt="Choose a value"
          options={Ecto.Enum.values(Discussit.Accounts.Account, :plan)}
        />
        <:actions>
          <.button phx-disable-with="Saving...">Save Account</.button>
        </:actions>
      </.simple_form>
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
    case Accounts.update_account(socket.assigns.account, account_params) do
      {:ok, account} ->
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

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_account(socket, :new, account_params) do
    with {:ok, account} <- Accounts.create_account(account_params),
         {:ok, _account_user} <-
           AccountUsers.create_account_user(%{
             account_id: account.id,
             user_id: socket.assigns.current_user.id
           }) do
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
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
