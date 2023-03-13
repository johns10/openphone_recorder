defmodule OpenphoneRecorder.EventsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `OpenphoneRecorder.Events` context.
  """

  @doc """
  Generate a event.
  """
  def event_fixture(attrs \\ %{}) do
    {:ok, event} =
      attrs
      |> Enum.into(%{
        payload: %{}
      })
      |> OpenphoneRecorder.Events.create_event()

    event
  end
end
