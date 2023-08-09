defmodule DiscussitWeb.UserSettingLive.Form do
  alias Tzdata.TimeZoneDatabase
  use DiscussitWeb, :live_view

  alias Discussit.UserSettings

  def render(assigns) do
    ~H"""
    <.header class="text-center">
      Account Settings
      <:subtitle>Manage your account email address and password settings</:subtitle>
    </.header>

    <div class="space-y-6 divide-y">
      <div>
        <.live_component
          module={DiscussitWeb.UserSettingLive.FormComponent}
          id={@user_setting.id || :new}
          title="User Options"
          action={:edit}
          user_setting={@user_setting}
          patch={~p"/users/options/#{@user_setting}"}
        />
      </div>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    user_setting = UserSettings.get_user_setting!(id)

    case Bodyguard.permit(
           UserSettings,
           :get_user_setting!,
           socket.assigns.current_user,
           user_setting
         ) do
      :ok ->
        {:noreply,
         socket
         |> assign(:user_setting, user_setting)}

      {:error, :unauthorized} ->
        {:noreply,
         socket
         |> push_navigate(to: ~p"/home")
         |> put_flash(:error, "You cannot access this contact")}
    end
  end
end
