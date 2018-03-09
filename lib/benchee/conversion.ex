defmodule Benchee.Conversion do
  @moduledoc """
  Integration of the conversion of multiple units with benchee.

  Can be used by plugins to use benchee unit scaling logic.
  """

  alias Benchee.Conversion.{Duration, Count, Memory}
  alias Benchee.Benchmark.Scenario

  @doc """
  Takes scenarios and a given scaling_strategy, returns the best units for the
  given scaling strategy. The return value changes based on whether you want
  units for run time or memory usage.

  The units can then be passed on to the appropriate `format` calls to format
  the output of arbitrary values with the right unit.

  ## Examples

      iex> statistics = %Benchee.Statistics{average: 1000.0, ips: 1000.0}
      iex> scenario = %Benchee.Benchmark.Scenario{
      ...>   run_time_statistics: statistics,
      ...>   memory_usage_statistics: statistics
      ...> }
      iex> Benchee.Conversion.units([scenario], :best)
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
                  },
        memory:   %Benchee.Conversion.Unit{
                    label: "B",
                    long: "Bytes",
                    magnitude: 1,
                    name: :byte
                  }
      }
  """
  def units(scenarios, scaling_strategy) do
    run_time_measurements =
      scenarios
      |> Enum.flat_map(fn scenario -> Map.to_list(scenario.run_time_statistics) end)
      |> Enum.group_by(fn {stat_name, _} -> stat_name end, fn {_, value} -> value end)

    memory_measurements =
      scenarios
      |> Enum.flat_map(fn
        %Scenario{memory_usage_statistics: nil} ->
          []

        %Scenario{memory_usage_statistics: memory_usage_statistics} ->
          Map.to_list(memory_usage_statistics)
      end)
      |> Enum.group_by(fn {stat_name, _} -> stat_name end, fn {_, value} -> value end)

    memory_average =
      case memory_measurements do
        map when map_size(map) == 0 -> []
        _ -> memory_measurements.average
      end

    %{
      run_time: Duration.best(run_time_measurements.average, strategy: scaling_strategy),
      ips: Count.best(run_time_measurements.ips, strategy: scaling_strategy),
      memory: Memory.best(memory_average, strategy: scaling_strategy)
    }
  end
end
