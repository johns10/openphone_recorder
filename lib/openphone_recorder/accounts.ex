defmodule OpenphoneRecorder.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  alias OpenphoneRecorder.Repo

  alias OpenphoneRecorder.Accounts.Account

  def list_accounts(opts \\ []) do
    preloads = Keyword.get(opts, :preloads, [])

    Account
    |> preload(^preloads)
    |> Repo.all()
  end

  def get_account!(id, opts \\ []) do
    preloads = Keyword.get(opts, :preloads, [])

    Account
    |> preload(^preloads)
    |> Repo.get!(id)
  end

  def create_account(attrs \\ %{}) do
    %Account{}
    |> Account.changeset(attrs)
    |> Repo.insert()
  end

  def update_account(%Account{} = account, attrs) do
    account
    |> Account.changeset(attrs)
    |> Repo.update()
  end

  def delete_account(%Account{} = account) do
    Repo.delete(account)
  end

  def change_account(%Account{} = account, attrs \\ %{}) do
    Account.changeset(account, attrs)
  end
end
