defmodule OpenphoneRecorder.UserSettings.UserSetting do
  use Ecto.Schema
  import Ecto.Changeset
  alias OpenphoneRecorder.Accounts.Account
  alias OpenphoneRecorder.Users.User

  schema "user_settings" do
    belongs_to :selected_account, Account, type: :binary_id
    belongs_to :user, User

    timestamps()
  end

  @doc false
  def changeset(user_setting, attrs) do
    user_setting
    |> cast(attrs, [:selected_account_id, :user_id])
    |> validate_required([])
    |> foreign_key_constraint(:selected_account_id)
    |> foreign_key_constraint(:user_id)
    |> unique_constraint([:user_id])
  end
end
