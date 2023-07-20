defmodule Discussit.DateSupport do
  alias PgRanges.TsRange

  def start_of_today(opts) do
    Keyword.get(opts, :timezone, "Etc/UTC")
    |> DateTime.now!()
    |> DateTime.to_date()
    |> start_of_day(opts)
  end

  def start_of_day(%NaiveDateTime{} = date_time, opts) do
    time_zone = Keyword.get(opts, :timezone, "Etc/UTC")

    date_time
    |> DateTime.from_naive!(time_zone)
    |> DateTime.to_date()
    |> start_of_day(opts)
  end

  def start_of_day(%Date{} = date, opts) do
    timezone = Keyword.get(opts, :timezone, "Etc/UTC")
    DateTime.new!(date, ~T[00:00:00], timezone)
  end

  def end_of_today(opts) do
    Keyword.get(opts, :timezone, "Etc/UTC")
    |> DateTime.now!()
    |> DateTime.to_date()
    |> end_of_day(opts)
  end

  def end_of_day(%NaiveDateTime{} = date_time, opts) do
    time_zone = Keyword.get(opts, :timezone, "Etc/UTC")

    date_time
    |> DateTime.from_naive!(time_zone)
    |> DateTime.to_date()
    |> end_of_day(opts)
  end

  def end_of_day(%Date{} = date, opts) do
    timezone = Keyword.get(opts, :timezone, "Etc/UTC")
    DateTime.new!(date, ~T[23:59:59], timezone)
  end

  def range_day(%TsRange{lower: lower, upper: upper}, opts) do
    time_zone = Keyword.get(opts, :timezone, "Etc/UTC")

    lower_date =
      lower
      |> DateTime.from_naive!(time_zone)
      |> DateTime.to_date()

    upper_date =
      upper
      |> DateTime.from_naive!(time_zone)
      |> DateTime.to_date()

    if lower_date != upper_date do
      raise("day range is not a single day")
    else
      lower_date
    end
  end

  def week(%Date{} = date) do
    Timex.iso_week(date)
  end

  def beginning_of_week(%TsRange{lower: lower}, opts), do: beginning_of_week(lower, opts)

  def beginning_of_week(%NaiveDateTime{} = date_time, opts) do
    time_zone = Keyword.get(opts, :timezone, "Etc/UTC")

    date_time
    |> DateTime.from_naive!(time_zone)
    |> Timex.beginning_of_week()
  end

  def end_of_week(%TsRange{upper: upper}, opts), do: end_of_week(upper, opts)

  def end_of_week(%NaiveDateTime{} = date_time, opts) do
    time_zone = Keyword.get(opts, :timezone, "Etc/UTC")

    date_time
    |> DateTime.from_naive!(time_zone)
    |> Timex.end_of_week()
  end
end
