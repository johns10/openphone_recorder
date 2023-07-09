defmodule OpenphoneRecorder.AccountsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `OpenphoneRecorder.Accounts` context.
  """

  @doc """
  Generate a account.
  """
  def account_fixture(attrs \\ %{}) do
    {:ok, account} =
      attrs
      |> Enum.into(%{
        name: Faker.Company.name(),
        plan: :free
      })
      |> OpenphoneRecorder.Accounts.create_account()

    account
  end
end
