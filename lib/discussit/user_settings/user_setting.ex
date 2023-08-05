defmodule Discussit.UserSettings.UserSetting do
  use Ecto.Schema
  import Ecto.Changeset
  alias Discussit.Accounts.Account
  alias Discussit.Users.User

  schema "user_settings" do
    field :timezone, Ecto.Enum, values: [etc: "Etc/UTC", est: "EST", mst: "MST"]

    belongs_to :selected_account, Account, type: :binary_id
    belongs_to :user, User

    timestamps()
  end

  @doc false
  def changeset(user_setting, attrs) do
    user_setting
    |> cast(attrs, [:selected_account_id, :user_id, :timezone])
    |> validate_required([])
    |> foreign_key_constraint(:selected_account_id)
    |> foreign_key_constraint(:user_id)
    |> unique_constraint([:user_id])
  end
end
