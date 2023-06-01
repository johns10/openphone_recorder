defmodule OpenphoneRecorder.StatementsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `OpenphoneRecorder.Statements` context.
  """

  @doc """
  Generate a statement.
  """
  def statement_fixture(attrs \\ %{}) do
    {:ok, statement} =
      attrs
      |> Enum.into(%{
        external_id: Ecto.UUID.generate(),
        source: :openphone,
        content: "some content",
        occurred_at: ~U[2023-03-28 10:21:00Z],
        type: :call
      })
      |> OpenphoneRecorder.Statements.create_statement()

    statement
  end
end
