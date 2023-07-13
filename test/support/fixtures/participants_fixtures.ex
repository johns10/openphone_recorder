defmodule Discussit.ParticipantsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Discussit.Participants` context.
  """

  @doc """
  Generate a participant.
  """
  def participant_fixture(attrs \\ %{}) do
    {:ok, participant} =
      attrs
      |> Enum.into(%{

      })
      |> Discussit.Participants.create_participant()

    participant
  end
end
