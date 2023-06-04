defmodule OpenphoneRecorder.TimestampFixtures do
  def ten_minutes_ago(), do: DateTime.utc_now() |> DateTime.add(-10 * 60)
  def thirty_minutes_ago(), do: DateTime.utc_now() |> DateTime.add(-30 * 60)
  def forty_minutes_ago(), do: DateTime.utc_now() |> DateTime.add(-40 * 60)
  def twenty_hours_ago(), do: DateTime.utc_now() |> DateTime.add(-20 * 60 * 60)
  def fifty_hours_ago(), do: DateTime.utc_now() |> DateTime.add(-50 * 60 * 60)
  def sixty_hours_ago(), do: DateTime.utc_now() |> DateTime.add(-60 * 60 * 60)
end
