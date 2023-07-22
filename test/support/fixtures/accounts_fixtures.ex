defmodule Discussit.AccountsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Discussit.Accounts` context.
  """

  @doc """
  Generate a account.
  """
  def account_fixture(attrs \\ %{}) do
    {:ok, account} =
      attrs
      |> Enum.into(%{
        name: Faker.Company.name(),
        plan: :free,
        openphone_signing_secret: "TGNwdWZzbjhSVmRaQ0NBZTJtN3FRdU05QkF1amd1Z1E="
      })
      |> Discussit.Accounts.create_account()

    account
  end
end
