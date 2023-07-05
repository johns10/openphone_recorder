defmodule OpenphoneRecorder.DateSupport do
  alias PgRanges.TsRange

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
end
