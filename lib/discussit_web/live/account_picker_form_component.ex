defmodule DiscussitWeb.AccountPickerFormComponent do
  use DiscussitWeb, :live_component

  alias Discussit.Users
  alias Discussit.Accounts
  alias Discussit.Accounts.Account

  @impl true
  def render(assigns) do
    ~H"""
    <div class="dropdown dropdown-right">
      <label tabindex="0">
        <div class="flex flex-row items-center justify-items-end hover:cursor-pointer">
          <div class="btn btn-ghost btn-sm px-2">
            <.icon name="hero-user-group" class={"w-5 h-5 #{@accounts == [] && "animate-pulse"}"} />
          </div>
          <%= if @user.selected_account_id do %>
            <div class="dropdown-label mr-2" style="display: none;">
              <%= @account.name %>
            </div>
          <% end %>
        </div>
      </label>
      <ul class="p-2 shadow menu dropdown-content z-[1] bg-base-200 rounded-box w-64">
        <%= for account <- @accounts do %>
          <li>
            <div class="flex flex-row justify-between">
              <.link
                phx-click={JS.push("select-account", value: %{id: account.id})}
                phx-target={@myself}
              >
                <%= account.name %>
              </.link>
            </div>
          </li>
        <% end %>
        <li>
          <.link href={~p{/accounts/new_standalone?#{[user_id: @user.id]}}}>
            Create New Account
          </.link>
        </li>
      </ul>
    </div>
    """
  end

  @impl true
  def update(%{user: user} = assigns, socket) do
    changeset = Users.change_selected_account(user)
    accounts = Accounts.list_accounts(filters: [user_id: user.id])

    account =
      if user.selected_account_id do
        Accounts.get_account!(user.selected_account_id)
      else
        %Account{name: "No Account Selected"}
      end

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:account, account)
     |> assign(:accounts, accounts)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("select-account", %{"id" => id}, socket) do
    case Users.update_selected_account(socket.assigns.user, %{selected_account_id: id}) do
      {:ok, _user} ->
        user = Users.get_user!(socket.assigns.user.id, preloads: :selected_account)

        notify_parent({:account_picked, user})

        {:noreply,
         socket
         |> put_flash(:info, "User setting updated successfully")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
