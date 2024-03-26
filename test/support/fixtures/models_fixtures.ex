defmodule Discussit.ModelsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Discussit.Models` context.
  """

  @doc """
  Generate a model.
  """
  def model_fixture(attrs \\ %{}) do
    {:ok, model} =
      attrs
      |> Enum.into(%{
        name: "some model name",
        external_id: "gpt-3.5-turbo",
        type: :llm,
        merge_object: "some merge_object",
        model_object: "some model_object",
        version: 42
      })
      |> Discussit.Models.create_model()

    model
  end
end
