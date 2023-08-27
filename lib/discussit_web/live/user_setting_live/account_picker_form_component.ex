defmodule DiscussitWeb.UserSettingLive.AccountPickerFormComponent do
  use DiscussitWeb, :live_component

  alias Discussit.UserSettings
  alias Discussit.Accounts

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex flex-row items-center justify-items-end">
      <details class="dropdown dropdown-right">
        <summary class="btn btn-ghost btn-sm px-2">
          <.icon name="hero-user-group" class={["w-5 h-5",  @accounts == [] && "animate-pulse"]} />
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
      <%= if @user_setting.selected_account_id do %>
        <.link
          class="dropdown-label mr-2 hover:cursor-pointer"
          style="display: none;"
          href={~p"/accounts/#{@user_setting.selected_account_id}"}
        >
          <%= if @user_setting.selected_account do %>
            <%= @user_setting |> Map.get(:selected_account, %{name: ""}) |> Map.get(:name, "") %>
          <% end %>
        </.link>
      <% end %>
    </div>
    """
  end

  @impl true
  def update(%{user_setting: user_setting, user: user} = assigns, socket) do
    changeset = UserSettings.change_user_setting(user_setting)

    accounts = Accounts.list_accounts(filters: [user_id: user.id])

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:accounts, accounts)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("select-account", %{"id" => id}, socket) do
    case UserSettings.update_user_setting(socket.assigns.user_setting, %{selected_account_id: id}) do
      {:ok, user_setting} ->
        user_setting = UserSettings.get_user_setting!(user_setting.id, preload: :selected_account)

        notify_parent({:account_picked, user_setting})

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
