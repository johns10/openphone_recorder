defmodule DiscussitWeb.UserSettingLive.FormComponent do
  use DiscussitWeb, :live_component

  alias Discussit.UserSettings
  import DiscussitWeb.LiveSupport

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.simple_form
        for={@form}
        id="user_setting-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input
          field={@form[:timezone]}
          type="select"
          label="timezone"
          prompt="Choose a value"
          options={select_options(Discussit.UserSettings.UserSetting, :timezone)}
        />
        <:actions>
          <.button phx-disable-with="Saving...">Save User setting</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{user_setting: user_setting} = assigns, socket) do
    changeset = UserSettings.change_user_setting(user_setting)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"user_setting" => user_setting_params}, socket) do
    changeset =
      socket.assigns.user_setting
      |> UserSettings.change_user_setting(user_setting_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"user_setting" => user_setting_params}, socket) do
    save_user_setting(socket, socket.assigns.action, user_setting_params)
  end

  defp save_user_setting(socket, :edit, user_setting_params) do
    case UserSettings.update_user_setting(socket.assigns.user_setting, user_setting_params) do
      {:ok, user_setting} ->
        notify_parent({:saved, user_setting})

        {:noreply,
         socket
         |> put_flash(:info, "User setting updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_user_setting(socket, :new, user_setting_params) do
    case UserSettings.create_user_setting(user_setting_params) do
      {:ok, user_setting} ->
        notify_parent({:saved, user_setting})

        {:noreply,
         socket
         |> put_flash(:info, "User setting created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
