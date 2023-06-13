defmodule OpenphoneRecorder.SummarizersFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `OpenphoneRecorder.Summarizers` context.
  """

  @doc """
  Generate a summarizer.
  """
  def summarizer_fixture(attrs \\ %{}) do
    {:ok, summarizer} =
      attrs
      |> Enum.into(%{
        prompt: "some prompt",
        chunker: :temporal
      })
      |> OpenphoneRecorder.Summarizers.create_summarizer()

    summarizer
  end
end
