defmodule OpenphoneRecorder.AccountUsersFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `OpenphoneRecorder.AccountUsers` context.
  """

  @doc """
  Generate a account_user.
  """
  def account_user_fixture(attrs \\ %{}) do
    {:ok, account_user} =
      attrs
      |> Enum.into(%{

      })
      |> OpenphoneRecorder.AccountUsers.create_account_user()

    account_user
  end
end
