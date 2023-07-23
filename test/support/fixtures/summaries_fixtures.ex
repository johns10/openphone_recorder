defmodule Discussit.SummariesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Discussit.Summaries` context.
  """

  @doc """
  Generate a summary.
  """
  def summary_fixture(attrs \\ %{}) do
    {:ok, summary} =
      attrs
      |> Enum.into(%{
        content: "some content",
        params: %{},
        chunker: :daily
      })
      |> Discussit.Summaries.create_summary()

    summary
  end
end
