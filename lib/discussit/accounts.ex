defmodule Discussit.Accounts do
  @behaviour Bodyguard.Policy
  import Ecto.Query, warn: false
  alias Discussit.Repo
  alias Discussit.Accounts.Account

  def authorize(:get_account!, user, account_id) do
    if user.email in DiscussitWeb.UserAuth.administrator_emails() do
      :ok
    else
      account_ids =
        list_accounts(filters: [user_id: user.id])
        |> Enum.map(& &1.id)

      if account_id in account_ids, do: :ok, else: :error
    end
  end

  def sum_available_credits(account_id) do
    credits = Discussit.Credits.sum_credits(filters: [account_id: account_id])
    usages = Discussit.Usages.sum_usages(filters: [account_id: account_id])

    credits - 4 * usages
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
    includes = Keyword.get(opts, :includes, [])

    Account
    |> include_available_credits(if includes[:available_credits], do: id, else: nil)
    |> preload(^preloads)
    |> Repo.get!(id)
  end

  defp filter_by_user_id(query, nil), do: query

  defp filter_by_user_id(query, user_id) do
    query
    |> join(:left, [a], user_accounts in assoc(a, :account_users), as: :au)
    |> where([au: au], au.user_id == ^user_id)
  end

  defp include_available_credits(query, nil), do: query

  defp include_available_credits(query, id) do
    credits = Discussit.Credits.sum_credits_query(filters: [account_id: id])
    usages = Discussit.Usages.sum_usages_query(filters: [account_id: id])

    select(query, [a], %{a | available_credits: subquery(credits) - 4 * subquery(usages)})
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

  def cast_openai_config(%Account{openai_api_key: openai_api_key}) do
    openai_apikey = openai_api_key || System.get_env("OPENAI_API_KEY")
    %OpenAI.Config{api_key: openai_apikey, http_options: [recv_timeout: 10 * 60 * 1000]}
  end
end
