defmodule OpenphoneRecorder.UserSettings do
  @behaviour Bodyguard.Policy
  import Ecto.Query, warn: false
  alias OpenphoneRecorder.Repo
  alias OpenphoneRecorder.UserSettings.UserSetting

  def default_preloads(), do: [:user, :selected_account]

  def authorize(:get_user_setting!, %{id: user_id}, %{user_id: user_id}), do: :ok
  def authorize(:get_user_setting!, _user, _user_setting), do: :error

  def authorize(:update_user_setting, %{id: user_id}, %{user_id: user_id}), do: :ok
  def authorize(:update_user_setting, _user, _user_setting), do: :error

  def list_user_settings(opts \\ []) do
    preload = Keyword.get(opts, :preload, default_preloads())

    from(u in UserSetting, preload: ^preload)
    |> Repo.all()
  end

  def get_user_setting!(_get_by, opts \\ [])

  def get_user_setting!(%{user_id: user_id}, opts) do
    preload = Keyword.get(opts, :preload, default_preloads())

    Repo.get_by!(UserSetting, user_id: user_id)
    |> preload_user_setting(preload)
  end

  def get_user_setting!(id, opts) do
    preload = Keyword.get(opts, :preload, default_preloads())

    from(UserSetting, preload: ^preload)
    |> Repo.get!(id)
  end

  def get_user_setting(%{user_id: user_id}, opts \\ []) do
    preload = Keyword.get(opts, :preload, default_preloads())

    Repo.get_by(UserSetting, user_id: user_id)
    |> preload_user_setting(preload)
  end

  def preload_user_setting(user_setting, preloads \\ default_preloads()) do
    Repo.preload(user_setting, preloads)
  end

  def get_or_insert_user_setting!(attrs \\ %{}) do
    %UserSetting{}
    |> UserSetting.changeset(attrs)
    |> Repo.insert()
    |> case do
      {:error, %{changes: %{user_id: user_id}, errors: [user_id: {"has already been taken", _}]}} ->
        get_user_setting(%{user_id: user_id})

      {:ok, user_setting} ->
        user_setting
    end
  end

  def create_user_setting(attrs \\ %{}) do
    %UserSetting{}
    |> UserSetting.changeset(attrs)
    |> Repo.insert()
  end

  def update_user_setting(%UserSetting{} = user_setting, attrs) do
    user_setting
    |> UserSetting.changeset(attrs)
    |> Repo.update()
    |> preload_result()
  end

  def delete_user_setting(%UserSetting{} = user_setting) do
    Repo.delete(user_setting)
  end

  def change_user_setting(%UserSetting{} = user_setting, attrs \\ %{}) do
    UserSetting.changeset(user_setting, attrs)
  end

  defp preload_result(result) do
    case result do
      {:ok, user_setting} ->
        {:ok, Repo.preload(user_setting, default_preloads())}

      other ->
        other
    end
  end
end
