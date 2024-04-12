defmodule Discussit.LayeredSummarizersFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Discussit.LayeredSummarizers` context.
  """

  @doc """
  Generate a layered_summarizer.
  """
  def layered_summarizer_fixture(attrs \\ %{}) do
    {:ok, layered_summarizer} =
      attrs
      |> Enum.into(%{
        name: "some name"
      })
      |> Discussit.LayeredSummarizers.create_layered_summarizer()

    layered_summarizer
  end
end
