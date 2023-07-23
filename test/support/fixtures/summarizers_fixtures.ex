defmodule Discussit.SummarizersFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Discussit.Summarizers` context.
  """

  @doc """
  Generate a summarizer.
  """
  def summarizer_fixture(attrs \\ %{}) do
    {:ok, summarizer} =
      attrs
      |> Enum.into(%{
        prompt: "some prompt",
        chunker: :daily
      })
      |> Discussit.Summarizers.create_summarizer()

    summarizer
  end
end
