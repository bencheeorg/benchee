defmodule Benchee.Conversion do
  @moduledoc """
  Integration of the conversion of multiple units with benchee.

  Can be used by plugins to use benchee unit scaling logic.
  """

  alias Benchee.Conversion.{Duration, Count, Memory}

  @doc """
  Takes scenarios and a given scaling_strategy, returns the best units for the
  given scaling strategy. The return value changes based on whether you want
  units for run time or memory usage.

  The units can then be passed on to the appropriate `format` calls to format
  the output of arbitrary values with the right unit.

  ## Examples

      iex> statistics = %Benchee.Statistics{average: 1000.0, ips: 1000.0}
      iex> scenario = %Benchee.Benchmark.Scenario{run_time_statistics: statistics}
      iex> Benchee.Conversion.units([scenario], :best, :run_time)
      %{
        ips:      %Benchee.Conversion.Unit{
                    label: "K",
                    long: "Thousand",
                    magnitude: 1000,
                    name: :thousand
                  },
        run_time: %Benchee.Conversion.Unit{
                    label: "ms",
                    long: "Milliseconds",
                    magnitude: 1000,
                    name: :millisecond
                  }
      }
  """
  def units(scenarios, scaling_strategy, :run_time) do
    measurements =
      scenarios
      |> Enum.flat_map(fn scenario ->
        Map.to_list(scenario.run_time_statistics)
      end)
      |> Enum.group_by(fn {stat_name, _} -> stat_name end, fn {_, value} -> value end)

    %{
      run_time: Duration.best(measurements.average, strategy: scaling_strategy),
      ips: Count.best(measurements.ips, strategy: scaling_strategy)
    }
  end

  def units(scenarios, scaling_strategy, :memory) do
    measurements =
      scenarios
      |> Enum.flat_map(fn scenario ->
        Map.to_list(scenario.memory_usage_statistics)
      end)
      |> Enum.group_by(fn {stat_name, _} -> stat_name end, fn {_, value} -> value end)

    %{memory: Memory.best(measurements.average, strategy: scaling_strategy)}
  end

  @deprecated "0.13"
  @doc """
  This is the old way of calling this function, which assumed that we were only
  dealing with run times and not memory units. After we have some time to update
  the formatters then we can remove this, but for now we'll just deprecate it.
  """
  def units(scenarios, scaling_strategy) do
    units(scenarios, scaling_strategy, :run_time)
  end
end
