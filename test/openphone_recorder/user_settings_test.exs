defmodule OpenphoneRecorder.UserSettingsTest do
  use OpenphoneRecorder.DataCase

  alias OpenphoneRecorder.UserSettings

  describe "user_settings" do
    alias OpenphoneRecorder.UserSettings.UserSetting

    import OpenphoneRecorder.UserSettingsFixtures
    import OpenphoneRecorder.UsersFixtures

    @invalid_attrs %{selected_account_id: Ecto.UUID.generate()}

    test "list_user_settings/0 returns all user_settings" do
      user_setting = user_setting_fixture()
      assert UserSettings.list_user_settings() == [nil_associations(user_setting)]
    end

    test "get_user_setting!/1 returns the user_setting with given id" do
      user_setting = user_setting_fixture()
      assert UserSettings.get_user_setting!(user_setting.id) == nil_associations(user_setting)
    end

    test "get_or_insert_user_setting/1 returns an existing user setting" do
      user = user_fixture()
      user_setting = user_setting_fixture(%{user_id: user.id})
      new_user_setting = UserSettings.get_or_insert_user_setting!(%{user_id: user.id})
      assert new_user_setting.id == user_setting.id
    end

    test "create_user_setting/1 with valid data creates a user_setting" do
      valid_attrs = %{}

      assert {:ok, %UserSetting{} = _user_setting} = UserSettings.create_user_setting(valid_attrs)
    end

    test "create_user_setting/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = UserSettings.create_user_setting(@invalid_attrs)
    end

    test "update_user_setting/2 with valid data updates the user_setting" do
      user_setting = user_setting_fixture()
      update_attrs = %{}

      assert {:ok, %UserSetting{} = _user_setting} =
               UserSettings.update_user_setting(user_setting, update_attrs)
    end

    test "update_user_setting/2 with invalid data returns error changeset" do
      user_setting = user_setting_fixture()

      assert {:error, %Ecto.Changeset{}} =
               UserSettings.update_user_setting(user_setting, @invalid_attrs)

      assert nil_associations(user_setting) == UserSettings.get_user_setting!(user_setting.id)
    end

    test "delete_user_setting/1 deletes the user_setting" do
      user_setting = user_setting_fixture()
      assert {:ok, %UserSetting{}} = UserSettings.delete_user_setting(user_setting)
      assert_raise Ecto.NoResultsError, fn -> UserSettings.get_user_setting!(user_setting.id) end
    end

    test "change_user_setting/1 returns a user_setting changeset" do
      user_setting = user_setting_fixture()
      assert %Ecto.Changeset{} = UserSettings.change_user_setting(user_setting)
    end
  end

  defp nil_associations(user_setting) do
    user_setting |> Map.put(:selected_account, nil) |> Map.put(:user, nil)
  end
end
