defmodule Discussit.TimestampFixtures do
  alias PgRanges.TsRange
  def ten_minutes_ago(), do: NaiveDateTime.utc_now() |> NaiveDateTime.add(-10 * 60)
  def thirty_minutes_ago(), do: NaiveDateTime.utc_now() |> NaiveDateTime.add(-30 * 60)
  def forty_minutes_ago(), do: NaiveDateTime.utc_now() |> NaiveDateTime.add(-40 * 60)
  def twenty_hours_ago(), do: NaiveDateTime.utc_now() |> NaiveDateTime.add(-20 * 60 * 60)
  def forty_hours_ago(), do: NaiveDateTime.utc_now() |> NaiveDateTime.add(-40 * 60 * 60)
  def fifty_hours_ago(), do: NaiveDateTime.utc_now() |> NaiveDateTime.add(-50 * 60 * 60)
  def sixty_hours_ago(), do: NaiveDateTime.utc_now() |> NaiveDateTime.add(-60 * 60 * 60)
  def eighty_hours_ago(), do: NaiveDateTime.utc_now() |> NaiveDateTime.add(-80 * 60 * 60)
  def hundred_hours_ago(), do: NaiveDateTime.utc_now() |> NaiveDateTime.add(-100 * 60 * 60)

  def yesterday(), do: NaiveDateTime.utc_now() |> NaiveDateTime.add(-24 * 60 * 60)
  def two_days_ago(), do: NaiveDateTime.utc_now() |> NaiveDateTime.add(-48 * 60 * 60)
  def three_days_ago(), do: NaiveDateTime.utc_now() |> NaiveDateTime.add(-72 * 60 * 60)
  def ten_days_ago(), do: NaiveDateTime.utc_now() |> NaiveDateTime.add(-240 * 60 * 60)

  def hours_ago(hours), do: NaiveDateTime.utc_now() |> NaiveDateTime.add(-hours * 60 * 60)
  def days_ago_range(n), do: days_ago(n) |> day_range()
  def days_ago(n), do: Date.utc_today() |> Date.add(-1 * n)

  def days_hours_ago(days, hours),
    do:
      Date.utc_today()
      |> Date.add(-1 * 7 * days)
      |> NaiveDateTime.new!(~T[00:00:00])
      |> NaiveDateTime.add(hours * 60 * 60)

  def months_weeks_ago(months, weeks),
    do: Date.utc_today() |> months_ago(months) |> Date.add(-1 * 7 * weeks)

  def day_range(date) do
    TsRange.new(
      DateTime.new!(date, ~T[00:00:00]),
      DateTime.new!(date, ~T[23:59:59])
    )
  end

  def weeks_ago_range(n), do: weeks_ago(n) |> week_range()
  def weeks_ago(n), do: Date.utc_today() |> Date.add(-1 * 7 * n)

  def week_range(date) do
    TsRange.new(
      DateTime.new!(date, ~T[00:00:00]) |> Timex.beginning_of_week(),
      DateTime.new!(date, ~T[23:59:59]) |> Timex.end_of_week()
    )
  end

  def months_ago_range(n),
    do:
      Enum.reduce(1..n, Date.utc_today(), fn _, date ->
        date |> Date.beginning_of_month() |> Date.add(-1)
      end)
      |> month_range()

  def months_ago(date, n), do: Enum.reduce(1..n, date, fn _, acc -> month_ago(acc) end)

  defp month_ago(%NaiveDateTime{} = date), do: date |> NaiveDateTime.to_date() |> month_ago()

  defp month_ago(%Date{day: day} = date) do
    days = max(day, Date.add(date, -day).day)

    Date.add(date, -days)
    |> Date.to_gregorian_days()
    |> Kernel.*(86400)
    |> Kernel.+(86399)
    |> NaiveDateTime.from_gregorian_seconds()
  end

  defp month_range(date) do
    TsRange.new(
      DateTime.new!(date, ~T[00:00:00]) |> Timex.beginning_of_month(),
      DateTime.new!(date, ~T[23:59:59]) |> Timex.end_of_month()
    )
  end
end
