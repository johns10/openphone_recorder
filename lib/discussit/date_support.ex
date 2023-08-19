defmodule Discussit.DateSupport do
  alias PgRanges.TsRange
  @default_timezone "Etc/UTC"

  def date(%NaiveDateTime{} = date_time, opts) do
    timezone = Keyword.get(opts, :timezone, @default_timezone)

    date_time
    |> DateTime.from_naive!(timezone)
    |> DateTime.to_date()
  end

  def start_of_today(opts) do
    Keyword.get(opts, :timezone, @default_timezone)
    |> DateTime.now!()
    |> DateTime.to_date()
    |> start_of_day(opts)
  end

  def start_of_day(%NaiveDateTime{} = date_time, opts) do
    timezone = Keyword.get(opts, :timezone, @default_timezone)

    date_time
    |> DateTime.from_naive!(timezone)
    |> DateTime.to_date()
    |> start_of_day(opts)
  end

  def start_of_day(%Date{} = date, opts) do
    timezone = Keyword.get(opts, :timezone, @default_timezone)
    DateTime.new!(date, ~T[00:00:00], timezone)
  end

  def end_of_today(opts) do
    Keyword.get(opts, :timezone, @default_timezone)
    |> DateTime.now!()
    |> DateTime.to_date()
    |> end_of_day(opts)
  end

  def end_of_day(%NaiveDateTime{} = date_time, opts) do
    timezone = Keyword.get(opts, :timezone, @default_timezone)

    date_time
    |> DateTime.from_naive!(timezone)
    |> DateTime.to_date()
    |> end_of_day(opts)
  end

  def end_of_day(%Date{} = date, opts) do
    timezone = Keyword.get(opts, :timezone, @default_timezone)
    DateTime.new!(date, ~T[23:59:59], timezone)
  end

  def range_day(%TsRange{lower: lower, upper: upper}, opts) do
    timezone = Keyword.get(opts, :timezone, @default_timezone)

    lower_date =
      lower
      |> DateTime.from_naive!(timezone)
      |> DateTime.to_date()

    upper_date =
      upper
      |> DateTime.from_naive!(timezone)
      |> DateTime.to_date()

    if lower_date != upper_date do
      raise("day range is not a single day")
    else
      lower_date
    end
  end

  def range_week_midpoint(%TsRange{lower: lower, upper: upper}, opts) do
    timezone = Keyword.get(opts, :timezone, @default_timezone)

    lower_week =
      lower
      |> DateTime.from_naive!(timezone)
      |> DateTime.to_date()
      |> Timex.iso_week()

    upper_week =
      upper
      |> DateTime.from_naive!(timezone)
      |> DateTime.to_date()
      |> Timex.iso_week()

    if lower_week != upper_week do
      raise("week range is not a single week")
    else
      NaiveDateTime.add(lower, 3 * 24 * 60 * 60 + 12 * 60 * 60)
    end
  end

  def week(%Date{} = date) do
    Timex.iso_week(date)
  end

  def beginning_of_week(%TsRange{lower: lower}, opts), do: beginning_of_week(lower, opts)

  def beginning_of_week(%NaiveDateTime{} = date_time, opts) do
    timezone = Keyword.get(opts, :timezone, @default_timezone)

    date_time
    |> DateTime.from_naive!(timezone)
    |> Timex.beginning_of_week()
  end

  def end_of_week(%TsRange{upper: upper}, opts), do: end_of_week(upper, opts)

  def end_of_week(%NaiveDateTime{} = date_time, opts) do
    timezone = Keyword.get(opts, :timezone, @default_timezone)

    date_time
    |> DateTime.from_naive!(timezone)
    |> Timex.end_of_week()
  end

  def beginning_of_month(%TsRange{lower: lower}, opts), do: beginning_of_month(lower, opts)

  def beginning_of_month(%NaiveDateTime{} = date_time, opts) do
    timezone = Keyword.get(opts, :timezone, @default_timezone)

    date_time
    |> DateTime.from_naive!(timezone)
    |> Timex.beginning_of_month()
  end

  def end_of_month(%TsRange{upper: upper}, opts), do: end_of_month(upper, opts)

  def end_of_month(%NaiveDateTime{} = date_time, opts) do
    timezone = Keyword.get(opts, :timezone, @default_timezone)

    date_time
    |> DateTime.from_naive!(timezone)
    |> Timex.end_of_month()
  end

  def beginning_of_year(%TsRange{lower: lower}, opts), do: beginning_of_year(lower, opts)

  def beginning_of_year(%NaiveDateTime{} = date_time, opts) do
    timezone = Keyword.get(opts, :timezone, @default_timezone)

    date_time
    |> DateTime.from_naive!(timezone)
    |> Timex.beginning_of_year()
  end

  def end_of_year(%TsRange{upper: upper}, opts), do: end_of_year(upper, opts)

  def end_of_year(%NaiveDateTime{} = date_time, opts) do
    timezone = Keyword.get(opts, :timezone, @default_timezone)

    date_time
    |> DateTime.from_naive!(timezone)
    |> Timex.end_of_year()
  end
end
