defmodule Discussit.ParticipantsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Discussit.Participants` context.
  """

  @doc """
  Generate a participant.
  """
  import Discussit.PhoneNumbersFixtures

  def participant_fixture(attrs \\ %{}) do
    {:ok, participant} =
      attrs
      |> Enum.into(%{
        phone_number_id: phone_number_fixture().id
      })
      |> Discussit.Participants.create_participant()

    participant
  end
end
