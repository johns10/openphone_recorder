defmodule OpenphoneRecorder.CallsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `OpenphoneRecorder.Calls` context.
  """

  @doc """
  Generate a call.
  """
  def call_fixture(attrs \\ %{}) do
    {:ok, call} =
      attrs
      |> Enum.into(%{
        external_id: "some external_id",
        source: :openphone
      })
      |> OpenphoneRecorder.Calls.create_call()

    call
  end
end
