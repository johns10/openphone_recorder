defmodule OpenphoneRecorderWeb.UserSettingLive.AccountPickerFormComponent do
  use OpenphoneRecorderWeb, :live_component

  alias OpenphoneRecorder.UserSettings
  alias OpenphoneRecorder.Accounts

  @impl true
  def render(assigns) do
    ~H"""
    <div class={@class}>
      <.form for={@form} id="account_picker-form" phx-target={@myself} phx-change="save">
        <.input field={@form[:selected_account_id]} type="raw_select" options={@account_options} />
      </.form>
    </div>
    """
  end

  @impl true
  def update(%{user_setting: user_setting, user: user} = assigns, socket) do
    changeset = UserSettings.change_user_setting(user_setting)

    account_options =
      Accounts.list_accounts(filters: [user_id: user.id]) |> Enum.map(&{&1.name, &1.id})

    accounts =
      {:ok,
       socket
       |> assign(assigns)
       |> assign(:account_options, account_options)
       |> assign_form(changeset)}
  end

  @impl true
  def handle_event("save", %{"user_setting" => params}, socket) do
    case UserSettings.update_user_setting(socket.assigns.user_setting, params) do
      {:ok, user_setting} ->
        notify_parent({:account_picked, user_setting})

        {:noreply,
         socket
         |> put_flash(:info, "User setting updated successfully")}

      {:error, %Ecto.Changeset{} = changeset} ->
        IO.inspect(changeset)
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
