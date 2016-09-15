defmodule Benchee.Units do
  @moduledoc """
  Provides scaling and labeling functions for numbers. Use "count" functions
  for numbers that represent countable things, such as iterations per second.
  Use "duration" functions for numbers that represent durations, such as run
  times.
  """

  @one_billion 1_000_000_000
  @one_million 1_000_000
  @one_thousand 1_000

  def scale_count(count) when count >= @one_billion,  do: {count / @one_billion, :billion}
  def scale_count(count) when count >= @one_million,  do: {count / @one_million, :million}
  def scale_count(count) when count >= @one_thousand, do: {count / @one_thousand, :thousand}
  def scale_count(count), do: {count, :one}

  @spec format_count(number) :: String.t
  def format_count(count) do
    count
    |> scale_count
    |> do_format
  end

  @microseconds_per_millisecond 1000
  @milliseconds_per_second 1000
  @seconds_per_minute 60
  @minutes_per_hour 60
  @microseconds_per_second @microseconds_per_millisecond * @milliseconds_per_second
  @microseconds_per_minute @microseconds_per_second * @seconds_per_minute
  @microseconds_per_hour @microseconds_per_minute * @minutes_per_hour

  def scale_duration(duration) when duration >= @microseconds_per_hour, do: {duration / @microseconds_per_hour, :hour}
  def scale_duration(duration) when duration >= @microseconds_per_minute, do: {duration / @microseconds_per_minute, :minute}
  def scale_duration(duration) when duration >= @microseconds_per_second, do: {duration / @microseconds_per_second, :second}
  def scale_duration(duration) when duration >= @microseconds_per_millisecond, do: {duration / @microseconds_per_millisecond, :millisecond}
  def scale_duration(duration), do: {duration, :microsecond}

  @spec format_duration(number) :: String.t
  def format_duration(duration) do
    duration
    |> scale_duration
    |> do_format
  end

  defp do_format({count, unit}) do
    "~.#{float_precision(count)}f~ts"
    |> :io_lib.format([count, unit_label(unit)])
    |> to_string
  end


  def float_precision(float) when float < 0.01, do: 5
  def float_precision(float) when float < 0.1, do: 4
  def float_precision(float) when float < 0.2, do: 3
  def float_precision(_float), do: 2

  @unit_labels %{
    billion:  %{ short: "B", long: "Billion"},
    million:  %{ short: "M", long: "Million"},
    thousand: %{ short: "K", long: "Thousand"},
    one:      %{ short: "", long: ""},

    hour:        %{ short: "h",  long: "Hours"},
    minute:      %{ short: "m",  long: "Minutes"},
    second:      %{ short: "s",  long: "Seconds"},
    millisecond: %{ short: "ms", long: "Milliseconds"},
    microsecond: %{ short: "μs", long: "Microseconds"}
  }

  def unit_label(unit) do
    @unit_labels
    |> Map.fetch!(unit)
    |> Map.fetch!(:short)
  end
end
