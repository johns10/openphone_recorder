defmodule Discussit.MeetingsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Discussit.Meetings` context.
  """

  @doc """
  Generate a meeting.
  """
  def meeting_fixture(attrs \\ %{}) do
    {:ok, meeting} =
      attrs
      |> Enum.into(%{
        occurred_at: ~N[2023-08-27 17:35:00.000000],
        source: :zoom,
        external_id: Ecto.UUID.generate(),
        name: "Name"
      })
      |> Discussit.Meetings.create_meeting()

    meeting
  end
end
