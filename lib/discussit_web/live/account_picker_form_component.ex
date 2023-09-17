defmodule DiscussitWeb.AccountPickerFormComponent do
  use DiscussitWeb, :live_component

  alias Discussit.Users
  alias Discussit.Accounts

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex flex-row items-center justify-items-end">
      <details class="dropdown dropdown-right">
        <summary class="btn btn-ghost btn-sm px-2">
          <.icon name="hero-user-group" class={"w-5 h-5 #{@accounts == [] && "animate-pulse"}"} />
        </summary>
        <ul class="p-2 shadow menu dropdown-content z-[1] bg-base-200 rounded-box w-52">
          <%= for account <- @accounts do %>
            <li>
              <.link phx-click="select-account" phx-value-id={account.id} phx-target={@myself}>
                <%= account.name %>
              </.link>
            </li>
          <% end %>
          <li>
            <.link href={~p{/accounts/new_standalone?#{[user_id: @user.id]}}}>
              Create New Account
            </.link>
          </li>
        </ul>
      </details>
      <%= if @user.selected_account_id do %>
        <.link
          class="dropdown-label mr-2 hover:cursor-pointer"
          style="display: none;"
          href={~p"/accounts/#{@user.selected_account_id}"}
        >
          <%= if @user.selected_account do %>
            <%= @user |> Map.get(:selected_account, %{name: ""}) |> Map.get(:name, "") %>
          <% end %>
        </.link>
      <% end %>
    </div>
    """
  end

  @impl true
  def update(%{user: user} = assigns, socket) do
    changeset = Users.change_selected_account(user)

    accounts = Accounts.list_accounts(filters: [user_id: user.id])

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:accounts, accounts)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("select-account", %{"id" => id}, socket) do
    case Users.update_selected_account(socket.assigns.user, %{selected_account_id: id}) do
      {:ok, user} ->
        user = Users.get_user!(socket.assigns.user.id, preload: :selected_account)

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
