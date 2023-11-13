defmodule Discussit.AccountUsersFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Discussit.AccountUsers` context.
  """

  @doc """
  Generate a account_user.
  """
  def account_user_fixture(attrs \\ %{}) do
    {:ok, account_user} =
      attrs
      |> Enum.into(%{})
      |> Discussit.AccountUsers.create_account_user()

    account_user
  end
end
