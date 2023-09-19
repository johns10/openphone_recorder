defmodule Discussit.Credits do
  @moduledoc """
  The Credits context.
  """

  import Ecto.Query, warn: false
  alias Discussit.Repo

  alias Discussit.Credits.Credit

  def sum_credits(opts \\ []) do
    sum_credits_query(opts)
    |> Repo.one()
  end

  def sum_credits_query(opts) do
    filters = Keyword.get(opts, :filters, [])

    Credit
    |> filter_by_account_id(filters[:account_id])
    |> select([c], sum(c.quantity))
  end

  def list_credits(opts \\ []) do
    filters = Keyword.get(opts, :filters, [])

    Credit
    |> filter_by_account_id(filters[:account_id])
    |> Repo.all()
  end

  def get_credit!(id), do: Repo.get!(Credit, id)

  defp filter_by_account_id(query, nil), do: query

  defp filter_by_account_id(query, account_id) do
    query
    |> where([c], c.account_id == ^account_id)
  end

  def create_credit(attrs \\ %{}) do
    %Credit{}
    |> Credit.changeset(attrs)
    |> Repo.insert()
  end

  def update_credit(%Credit{} = credit, attrs) do
    credit
    |> Credit.changeset(attrs)
    |> Repo.update()
  end

  def delete_credit(%Credit{} = credit) do
    Repo.delete(credit)
  end

  def change_credit(%Credit{} = credit, attrs \\ %{}) do
    Credit.changeset(credit, attrs)
  end
end
