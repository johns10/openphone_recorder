defmodule OpenphoneRecorder.Accounts do
  @moduledoc """
  The Accounts context.
  """
  @behaviour Bodyguard.Policy

  import Ecto.Query, warn: false
  alias OpenphoneRecorder.Repo

  alias OpenphoneRecorder.Accounts.Account

  def authorize(:get_account!, user, account_id) do
    if user.email in OpenphoneRecorderWeb.UserAuth.administrator_emails() do
      :ok
    else
      account_ids =
        list_accounts(filters: [user_id: user.id])
        |> Enum.map(& &1.id)

      if account_id in account_ids, do: :ok, else: :error
    end
  end

  def list_accounts(opts \\ []) do
    preloads = Keyword.get(opts, :preloads, [])
    filters = Keyword.get(opts, :filters, [])

    Account
    |> filter_by_user_id(filters[:user_id])
    |> preload(^preloads)
    |> Repo.all()
  end

  def get_account!(id, opts \\ []) do
    preloads = Keyword.get(opts, :preloads, [])

    Account
    |> preload(^preloads)
    |> Repo.get!(id)
  end

  defp filter_by_user_id(query, nil), do: query

  defp filter_by_user_id(query, user_id) do
    query
    |> join(:left, [a], user_accounts in assoc(a, :account_users), as: :au)
    |> where([au: au], au.user_id == ^user_id)
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
