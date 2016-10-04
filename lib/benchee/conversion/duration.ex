defmodule Benchee.Conversion.Duration do
  @moduledoc """
  Unit scaling for duration converting from microseconds to minutes and others.
  """

  alias Benchee.Conversion.{Format, Scale}

  @behaviour Scale
  @behaviour Format

  @microseconds_per_millisecond 1000
  @milliseconds_per_second 1000
  @seconds_per_minute 60
  @minutes_per_hour 60
  @microseconds_per_second @microseconds_per_millisecond * @milliseconds_per_second
  @microseconds_per_minute @microseconds_per_second * @seconds_per_minute
  @microseconds_per_hour @microseconds_per_minute * @minutes_per_hour

  @units %{
    hour:        %{
                    magnitude: @microseconds_per_hour,
                    short:     "h",
                    long:      "Hours"
                  },
    minute:      %{
                    magnitude: @microseconds_per_minute,
                    short:     "m",
                    long: "Minutes"
                  },
    second:      %{
                    magnitude: @microseconds_per_second,
                    short:     "s",
                    long:      "Seconds"
                  },
    millisecond: %{
                    magnitude: @microseconds_per_millisecond,
                    short:     "ms",
                    long:      "Milliseconds"
                  },
    microsecond: %{
                    magnitude: 1,
                    short:     "μs",
                    long: "Microseconds"
                  }
  }

  @doc """
  Scales a duration value in microseconds into a larger unit if appropriate

  ## Examples

      iex> Benchee.Conversion.Duration.scale(1)
      {1, :microsecond}

      iex> Benchee.Conversion.Duration.scale(1_234)
      {1.234, :millisecond}

      iex> Benchee.Conversion.Duration.scale(11_234_567_890.123)
      {3.1207133028119443, :hour}

  """
  def scale(duration) when duration >= @microseconds_per_hour do
    scale_with_unit duration, :hour
  end
  def scale(duration) when duration >= @microseconds_per_minute do
    scale_with_unit duration, :minute
  end
  def scale(duration) when duration >= @microseconds_per_second do
    scale_with_unit duration, :second
  end
  def scale(duration) when duration >= @microseconds_per_millisecond do
    scale_with_unit duration, :millisecond
  end
  def scale(duration) do
    scale_with_unit duration, :microsecond
  end

  # Helper function for returning a tuple of {value, unit}
  defp scale_with_unit(duration, unit) do
    {scale(duration, unit), unit}
  end

  @doc """
  Scales a duration value in microseconds into a value in the specified unit

  ## Examples

      iex> Benchee.Conversion.Duration.scale(12345, :microsecond)
      12345

      iex> Benchee.Conversion.Duration.scale(12345, :millisecond)
      12.345

      iex> Benchee.Conversion.Duration.scale(12345, :minute)
      2.0575e-4

  """
  def scale(duration, :hour) do
    duration / @microseconds_per_hour
  end
  def scale(duration, :minute) do
    duration / @microseconds_per_minute
  end
  def scale(duration, :second) do
    duration / @microseconds_per_second
  end
  def scale(duration, :millisecond) do
    duration / @microseconds_per_millisecond
  end
  def scale(duration, :microsecond) do
    duration
  end

  @doc """
  Converts a value of the given unit into microseconds

  ## Examples

      iex> Benchee.Conversion.Duration.microseconds({1.234, :second})
      1_234_000.0

      iex> Benchee.Conversion.Duration.microseconds({1.234, :minute})
      7.404e7

      iex> Benchee.Conversion.Duration.microseconds({1.234, :minute}) |> Benchee.Conversion.Duration.scale(:minute)
      1.234

  """
  def microseconds({duration, :hour}) do
    duration * @microseconds_per_hour
  end
  def microseconds({duration, :minute}) do
    duration * @microseconds_per_minute
  end
  def microseconds({duration, :second}) do
    duration * @microseconds_per_second
  end
  def microseconds({duration, :millisecond}) do
    duration * @microseconds_per_millisecond
  end
  def microseconds({duration, :microsecond}) do
    duration
  end

  @doc """
  Formats a number as a string, with a unit label. To specify the unit, pass
  a tuple of `{value, unit_atom}` like `{1_234, :second}`

  ## Examples

      iex> Benchee.Conversion.Duration.format(45_678.9)
      "45.68 ms"

      iex> Benchee.Conversion.Duration.format(45.6789)
      "45.68 μs"

      iex> Benchee.Conversion.Duration.format({45.6789, :millisecond})
      "45.68 ms"

  """
  def format(count) do
    Format.format(count, __MODULE__)
  end

  @doc """
  Finds the best unit for a list of durations. By default, chooses the most common
  unit. In case of tie, chooses the largest of the most common units.

  Pass `[strategy: :smallest]` to always return the smallest unit in the list.
  Pass `[strategy: :largest]` to always return the largest unit in the list.

  ## Examples

      iex> Benchee.Conversion.Duration.best([23, 23_000, 34_000, 2_340_000])
      :millisecond

      iex> Benchee.Conversion.Duration.best([23, 23_000, 34_000, 2_340_000, 3_450_000])
      :second

      iex> Benchee.Conversion.Duration.best([23, 23_000, 34_000, 2_340_000], strategy: :smallest)
      :microsecond

      iex> Benchee.Conversion.Duration.best([23, 23_000, 34_000, 2_340_000], strategy: :largest)
      :second
  """
  def best(list, opts \\ [strategy: :best])
  def best(list, opts) do
    Scale.best_unit(list, __MODULE__, opts)
  end

  @doc """
  The label for the specified unit, as a string

  ## Examples

      iex> Benchee.Conversion.Duration.label(:millisecond)
      "ms"

      iex> Benchee.Conversion.Duration.label(:microsecond)
      "μs"
  """
  def label(unit) do
    Format.label(@units, unit)
  end

  @doc """
  The magnitude of the specified unit, as a number

  ## Examples

      iex> Benchee.Conversion.Duration.magnitude(:millisecond)
      1000

      iex> Benchee.Conversion.Duration.magnitude(:microsecond)
      1
  """
  def magnitude(unit) do
    Scale.magnitude(@units, unit)
  end

  @doc """
  A string that appears between a value and unit label when formatted. For
  this module, a space
  """
  def separator, do: " "

  @doc """
  The most basic unit in which measurements occur, microseconds.

  ## Examples

      iex> Benchee.Conversion.Duration.base_unit
      :microsecond

  """
  def base_unit, do: :microsecond
end
