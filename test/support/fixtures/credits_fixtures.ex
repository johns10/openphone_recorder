defmodule Discussit.CreditsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Discussit.Credits` context.
  """

  @doc """
  Generate a credit.
  """
  def credit_fixture(attrs \\ %{}) do
    {:ok, credit} =
      attrs
      |> Enum.into(%{
        product_id: "some product_id",
        purchased_at: ~N[2023-09-17 11:52:00],
        quantity: 120.5
      })
      |> Discussit.Credits.create_credit()

    credit
  end
end
