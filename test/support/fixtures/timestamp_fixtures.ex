defmodule OpenphoneRecorder.TimestampFixtures do
  def ten_minutes_ago(), do: DateTime.utc_now() |> DateTime.add(-10 * 60)
  def thirty_minutes_ago(), do: DateTime.utc_now() |> DateTime.add(-30 * 60)
  def forty_minutes_ago(), do: DateTime.utc_now() |> DateTime.add(-40 * 60)
  def twenty_hours_ago(), do: DateTime.utc_now() |> DateTime.add(-20 * 60 * 60)
  def forty_hours_ago(), do: DateTime.utc_now() |> DateTime.add(-40 * 60 * 60)
  def fifty_hours_ago(), do: DateTime.utc_now() |> DateTime.add(-50 * 60 * 60)
  def sixty_hours_ago(), do: DateTime.utc_now() |> DateTime.add(-60 * 60 * 60)
  def eighty_hours_ago(), do: DateTime.utc_now() |> DateTime.add(-80 * 60 * 60)
  def hundred_hours_ago(), do: DateTime.utc_now() |> DateTime.add(-100 * 60 * 60)

  def yesterday(), do: DateTime.utc_now() |> DateTime.add(-24 * 60 * 60)
  def two_days_ago(), do: DateTime.utc_now() |> DateTime.add(-48 * 60 * 60)
  def three_days_ago(), do: DateTime.utc_now() |> DateTime.add(-72 * 60 * 60)
  def ten_days_ago(), do: DateTime.utc_now() |> DateTime.add(-240 * 60 * 60)

  def months_ago(n), do: Enum.reduce(1..n, nil, fn _, acc -> month_ago(acc) end)

  defp month_ago(%Date{day: day} = date \\ Date.utc_today()) do
    days = max(day, Date.add(date, -day).day)

    Date.add(date, -days)
    |> Date.to_gregorian_days()
    |> Kernel.*(86400)
    |> Kernel.+(86399)
    |> DateTime.from_gregorian_seconds()
  end
end
