defmodule Benchee.Units do
  @moduledoc """
  Provides scaling and labeling functions for numbers. Use "count" functions
  for numbers that represent countable things, such as iterations per second.
  Use "duration" functions for numbers that represent durations, such as run
  times.
  """

  defmodule Count do
    alias Benchee.Units.Best

    @one_billion 1_000_000_000
    @one_million 1_000_000
    @one_thousand 1_000

    @units %{
      billion:  %{ magnitude: @one_billion, short: "B", long: "Billion"},
      million:  %{ magnitude: @one_million, short: "M", long: "Million"},
      thousand: %{ magnitude: @one_thousand, short: "K", long: "Thousand"},
      one:      %{ magnitude: 1, short: "", long: ""},
    }

    def scale(count) when count >= @one_billion,  do: {count / @one_billion, :billion}
    def scale(count) when count >= @one_million,  do: {count / @one_million, :million}
    def scale(count) when count >= @one_thousand, do: {count / @one_thousand, :thousand}
    def scale(count), do: {count, :one}

    @spec format(number) :: String.t
    def format(count) do
      Benchee.Units.Common.format(count, __MODULE__)
    end

    def best(list, opts \\ [strategy: :best])
    def best(list, opts) do
      Best.unit(list, __MODULE__, opts)
    end

    def magnitude(unit) do
      Benchee.Units.Common.magnitude(@units, unit)
    end

    def label(unit) do
      Benchee.Units.Common.label(@units, unit)
    end
  end

  defmodule Duration do
    alias Benchee.Units.Best

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

    def scale(duration) when duration >= @microseconds_per_hour, do: {duration / @microseconds_per_hour, :hour}
    def scale(duration) when duration >= @microseconds_per_minute, do: {duration / @microseconds_per_minute, :minute}
    def scale(duration) when duration >= @microseconds_per_second, do: {duration / @microseconds_per_second, :second}
    def scale(duration) when duration >= @microseconds_per_millisecond, do: {duration / @microseconds_per_millisecond, :millisecond}
    def scale(duration), do: {duration, :microsecond}

    @spec format(number) :: String.t
    def format(count) do
      Benchee.Units.Common.format(count, __MODULE__)
    end

    def best(list, opts \\ [strategy: :best])
    def best(list, opts) do
      Best.unit(list, __MODULE__, opts)
    end

    def label(unit) do
      Benchee.Units.Common.label(@units, unit)
    end

    def magnitude(unit) do
      Benchee.Units.Common.magnitude(@units, unit)
    end
  end

  defmodule Best do
    @moduledoc false

    def unit(list, module, opts)do
      case Keyword.get(opts, :strategy, :best) do
        :best -> best_unit(list, module)
        :largest -> largest_unit(list, module)
        :smallest -> smallest_unit(list, module)
      end
    end

    defp best_unit(list, module) do
      list
      |> Enum.map(&(scale_unit(&1, module)))
      |> Enum.reduce(%{}, &totals_by_unit/2)
      |> Enum.into([])
      |> Enum.sort(&(sort_by_total_and_magnitude(&1, &2, module)))
      |> hd
      |> elem(0)
    end

    defp smallest_unit(list, module) do
      list
      |> Enum.map(&(scale_unit(&1, module)))
      |> Enum.sort(&(sort_by_magnitude(&1, &2, module)))
      |> Enum.reverse
      |> hd
    end

    defp largest_unit(list, module) do
      list
      |> Enum.map(&(scale_unit(&1, module)))
      |> Enum.sort(&(sort_by_magnitude(&1, &2, module)))
      |> hd
    end

    defp scale_unit(count, module) do
      {_, unit} = module.scale(count)
      unit
    end

    defp totals_by_unit(unit, acc) do
      count = Map.get(acc, unit, 0)
      Map.put(acc, unit, count + 1)
    end

    defp sort_by_total_and_magnitude({units_a, total}, {units_b, total}, module) do
      sort_by_magnitude(units_a, units_b, module)
    end
    defp sort_by_total_and_magnitude({_, total_a}, {_, total_b}, _module) do
      total_a > total_b
    end

    defp sort_by_magnitude(a, b, module) do
      module.magnitude(a) > module.magnitude(b)
    end
  end

  defmodule Common do
    @moduledoc false

    def format({count, unit}, module) do
      "~.#{Benchee.Units.float_precision(count)}f~ts"
      |> :io_lib.format([count, module.label(unit)])
      |> to_string
    end

    def format(number, module) do
      number
      |> module.scale
      |> format(module)
    end

    def magnitude(units, unit) do
      units
      |> Map.fetch!(unit)
      |> Map.fetch!(:magnitude)
    end

    def label(units, unit) do
      units
      |> Map.fetch!(unit)
      |> Map.fetch!(:short)
    end
  end

  def float_precision(float) when float < 0.01, do: 5
  def float_precision(float) when float < 0.1, do: 4
  def float_precision(float) when float < 0.2, do: 3
  def float_precision(_float), do: 2
end
