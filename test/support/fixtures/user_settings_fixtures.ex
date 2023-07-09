defmodule OpenphoneRecorder.UserSettingsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `OpenphoneRecorder.UserSettings` context.
  """

  @doc """
  Generate a user_setting.
  """
  def user_setting_fixture(attrs \\ %{}) do
    {:ok, user_setting} =
      attrs
      |> Enum.into(%{

      })
      |> OpenphoneRecorder.UserSettings.create_user_setting()

    user_setting
  end
end
