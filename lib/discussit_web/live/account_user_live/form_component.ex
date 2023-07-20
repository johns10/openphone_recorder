defmodule DiscussitWeb.AccountUserLive.FormComponent do
  use DiscussitWeb, :live_component

  require Logger

  alias Discussit.AccountUsers.AccountUserForm
  alias Discussit.AccountUsers
  alias Discussit.Users.User
  alias Discussit.Users

  @impl true
  def render(assigns) do
    ~H"""
    <div class="mt-0">
      <.form
        for={@form}
        id="account-user-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:account_id]} type="hidden" value={@account_id} />

        <div class="flex">
          <.input
            field={@form[:email]}
            type="raw_input"
            class="rounded-r-none rounded-t-none"
            required
          />
          <.button type="submit" class="btn-success flex-shrink rounded-l-none rounded-t-none">
            Invite
          </.button>
        </div>
      </.form>
    </div>
    """
  end

  @impl true
  def update(%{account_user: account_user} = assigns, socket) do
    changeset = AccountUsers.change_account_user(account_user)
    form_changeset = AccountUsers.change_account_user_form(%AccountUserForm{})

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:changeset, changeset)
     |> assign_form(form_changeset)}
  end

  @impl true
  def handle_event("validate", %{"account_user_form" => params}, socket) do
    form_changeset =
      %AccountUserForm{}
      |> AccountUsers.change_account_user_form(params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :form_changeset, form_changeset)}
  end

  def handle_event("save", %{"account_user_form" => params}, socket) do
    with {:form, {:ok, result}} <- {:form, AccountUsers.create_account_user_form(params)},
         %AccountUserForm{email: email, account_id: account_id} <- result,
         {:user, {:ok, %User{id: id}}} <- {:user, upsert_user(email, socket)} do
      account_user_params = %{user_id: id, account_id: account_id}

      case AccountUsers.create_preloaded_account_user(account_user_params) do
        {:ok, account_user} ->
          changeset = AccountUsers.change_account_user(socket.assigns.account_user)
          form_changeset = AccountUsers.change_account_user_form(%AccountUserForm{email: ""})
          notify_parent({:new_account_user, account_user})

          {:noreply,
           socket
           |> put_flash(:info, "Account user updated successfully")
           |> assign(:changeset, changeset)
           |> assign_form(form_changeset)}

        {:error, %Ecto.Changeset{} = changeset} ->
          {:noreply, assign(socket, :changeset, changeset)}
      end
    else
      {:form, {:error, %Ecto.Changeset{} = form_changeset}} ->
        {:noreply, assign(socket, :form_changeset, form_changeset)}

      {:user, {:error, %Ecto.Changeset{} = _user_changeset}} ->
        Logger.warn("Failed to create user")
        {:noreply, socket}

      e ->
        Logger.error(inspect(e))
    end
  end

  defp upsert_user(email, %{assigns: %{current_user: user}}) do
    Users.get_user_by_email(email)
    |> case do
      %User{} = user ->
        {:ok, user}

      nil ->
        case Users.invite_user(%{email: email, invited_by_user_id: user.id}) do
          {:ok, user} ->
            Users.deliver_user_invitation_instructions(
              user,
              &url(~p"/users/invitation/#{&1}")
            )

            {:ok, user}

          {:error, %Ecto.Changeset{} = changeset} ->
            {:error, changeset}
        end
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
