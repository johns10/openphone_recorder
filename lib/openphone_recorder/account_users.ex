defmodule OpenphoneRecorder.AccountUsers do
  import Ecto.Query, warn: false
  alias OpenphoneRecorder.Repo

  alias OpenphoneRecorder.AccountUsers.AccountUser
  alias OpenphoneRecorder.AccountUsers.AccountUserForm

  def list_account_users do
    Repo.all(AccountUser)
  end

  def get_account_user!(id), do: Repo.get!(AccountUser, id)

  def create_account_user(attrs \\ %{}) do
    %AccountUser{}
    |> AccountUser.changeset(attrs)
    |> Repo.insert()
  end

  def create_preloaded_account_user(attrs \\ %{}) do
    %AccountUser{}
    |> AccountUser.changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, account_user} -> {:ok, Repo.preload(account_user, :user)}
      error -> error
    end
  end

  def update_account_user(%AccountUser{} = account_user, attrs) do
    account_user
    |> AccountUser.changeset(attrs)
    |> Repo.update()
  end

  def delete_account_user(%AccountUser{} = account_user) do
    Repo.delete(account_user)
  end

  def change_account_user(%AccountUser{} = account_user, attrs \\ %{}) do
    AccountUser.changeset(account_user, attrs)
  end

  def create_account_user_form(attrs \\ %{}) do
    %AccountUserForm{}
    |> AccountUserForm.changeset(attrs)
    |> Ecto.Changeset.apply_action(:insert)
  end

  def change_account_user_form(%AccountUserForm{} = account_user_form, attrs \\ %{}) do
    AccountUserForm.changeset(account_user_form, attrs)
  end
end
