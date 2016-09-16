defmodule Benchee.Unit.Duration do
  alias Benchee.Unit.Common

  @behaviour Benchee.Unit

  @microseconds_per_millisecond 1000
  @milliseconds_per_second 1000
  @seconds_per_minute 60
  @minutes_per_hour 60
  @microseconds_per_second @microseconds_per_millisecond * @milliseconds_per_second
  @microseconds_per_minute @microseconds_per_second * @seconds_per_minute
  @microseconds_per_hour @microseconds_per_minute * @minutes_per_hour

  @units %{
    hour:        %{ magnitude: @microseconds_per_hour, short: "h",  long: "Hours"},
    minute:      %{ magnitude: @microseconds_per_minute, short: "m",  long: "Minutes"},
    second:      %{ magnitude: @microseconds_per_second, short: "s",  long: "Seconds"},
    millisecond: %{ magnitude: @microseconds_per_millisecond, short: "ms", long: "Milliseconds"},
    microsecond: %{ magnitude: 1, short: "μs", long: "Microseconds"}
  }

  @doc """
  Scales a duration value in microseconds into a larger unit if appropriate

  ## Examples

      iex(3)> Benchee.Unit.Duration.scale(1)
      {1, :microsecond}

      iex(5)> Benchee.Unit.Duration.scale(1_234)
      {1.234, :millisecond}

      iex(8)> Benchee.Unit.Duration.scale(11_234_567_890.123)
      {3.1207133028119443, :hour}

  """
  def scale(duration) when duration >= @microseconds_per_hour, do: {duration / @microseconds_per_hour, :hour}
  def scale(duration) when duration >= @microseconds_per_minute, do: {duration / @microseconds_per_minute, :minute}
  def scale(duration) when duration >= @microseconds_per_second, do: {duration / @microseconds_per_second, :second}
  def scale(duration) when duration >= @microseconds_per_millisecond, do: {duration / @microseconds_per_millisecond, :millisecond}
  def scale(duration), do: {duration, :microsecond}

  def format(count) do
    Common.format(count, __MODULE__)
  end

  def best(list, opts \\ [strategy: :best])
  def best(list, opts) do
    Common.best_unit(list, __MODULE__, opts)
  end

  def label(unit) do
    Common.label(@units, unit)
  end

  def magnitude(unit) do
    Common.magnitude(@units, unit)
  end
end
