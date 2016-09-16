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

  def best_for_counts(list, opts \\ [strategy: :best])
  def best_for_counts(list, opts) do
    best_unit(list, Keyword.get(opts, :strategy, :best), &scale_count_unit/1)
  end

  def best_for_durations(list, opts \\ [strategy: :best])
  def best_for_durations(list, opts) do
    strategy = Keyword.get(opts, :strategy, :best)
    best_unit(list, strategy, &scale_duration_unit/1)
  end

  defp best_unit(list, strategy, scale_function) do
    case strategy do
      :best -> best_unit(list, scale_function)
      :largest -> largest_unit(list, scale_function)
      :smallest -> smallest_unit(list, scale_function)
    end
  end

  defp best_unit(list, scale) do
    list
    |> Enum.map(scale)
    |> Enum.reduce(%{}, &totals_by_unit/2)
    |> Enum.into([])
    |> Enum.sort(&sort_by_total_and_magnitude/2)
    |> hd
    |> elem(0)
  end

  defp smallest_unit(list, scale) do
    list
    |> Enum.map(scale)
    |> Enum.sort(&sort_by_magnitude/2)
    |> Enum.reverse
    |> hd
  end

  defp largest_unit(list, scale) do
    list
    |> Enum.map(scale)
    |> Enum.sort(&sort_by_magnitude/2)
    |> hd
  end

  defp scale_count_unit(count) do
    {_, unit} = scale_count(count)
    unit
  end

  defp scale_duration_unit(duration) do
    {_, unit} = scale_duration(duration)
    unit
  end

  defp totals_by_unit(unit, acc) do
    count = Map.get(acc, unit, 0)
    Map.put(acc, unit, count + 1)
  end

  defp sort_by_total_and_magnitude({units_a, total}, {units_b, total}) do
    sort_by_magnitude(units_a, units_b)
  end
  defp sort_by_total_and_magnitude({_, total_a}, {_, total_b}) do
    total_a > total_b
  end

  defp sort_by_magnitude(a, b) do
    magnitude(a) > magnitude(b)
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

  @units %{
    billion:  %{ magnitude: @one_billion, short: "B", long: "Billion"},
    million:  %{ magnitude: @one_million, short: "M", long: "Million"},
    thousand: %{ magnitude: @one_thousand, short: "K", long: "Thousand"},
    one:      %{ magnitude: 1, short: "", long: ""},

    hour:        %{ magnitude: @microseconds_per_hour, short: "h",  long: "Hours"},
    minute:      %{ magnitude: @microseconds_per_minute, short: "m",  long: "Minutes"},
    second:      %{ magnitude: @microseconds_per_second, short: "s",  long: "Seconds"},
    millisecond: %{ magnitude: @microseconds_per_millisecond, short: "ms", long: "Milliseconds"},
    microsecond: %{ magnitude: 1, short: "μs", long: "Microseconds"}
  }

  defp magnitude(unit) do
    @units
    |> Map.fetch!(unit)
    |> Map.fetch!(:magnitude)
  end

  def unit_label(unit) do
    @units
    |> Map.fetch!(unit)
    |> Map.fetch!(:short)
  end
end
