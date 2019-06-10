defmodule Benchee.Conversion do
  @moduledoc """
  Integration of the conversion of multiple units with benchee.

  Can be used by plugins to use benchee unit scaling logic.
  """

  alias Benchee.Scenario
  alias Benchee.Conversion.{Count, Duration, Memory}

  @doc """
  Takes scenarios and a given scaling_strategy, returns the best units for the
  given scaling strategy. The return value changes based on whether you want
  units for run time or memory usage.

  The units can then be passed on to the appropriate `format` calls to format
  the output of arbitrary values with the right unit.

  ## Examples

      iex> statistics = %Benchee.Statistics{average: 1_000_000.0, ips: 1000.0}
      iex> scenario = %Benchee.Scenario{
      ...>   run_time_data: %Benchee.CollectionData{statistics: statistics},
      ...>   memory_usage_data: %Benchee.CollectionData{statistics: statistics},
      ...>   reductions_data: %Benchee.CollectionData{statistics: statistics}
      ...> }
      iex> Benchee.Conversion.units([scenario], :best)
      %{
        ips:             %Benchee.Conversion.Unit{
                           label: "K",
                           long: "Thousand",
                           magnitude: 1000,
                           name: :thousand
                         },
        run_time:        %Benchee.Conversion.Unit{
                           label: "ms",
                           long: "Milliseconds",
                           magnitude: 1_000_000,
                           name: :millisecond
                         },
        memory:          %Benchee.Conversion.Unit{
                           label: "KB",
                           long: "Kilobytes",
                           magnitude: 1024,
                           name: :kilobyte
                         },
        reduction_count: %Benchee.Conversion.Unit{
                           label: "M",
                           long: "Million",
                           magnitude: 1000000,
                           name: :million
                         }
      }
  """
  def units(scenarios, scaling_strategy) do
    run_time_measurements =
      scenarios
      |> Enum.flat_map(fn scenario -> Map.to_list(scenario.run_time_data.statistics) end)
      |> Enum.group_by(fn {stat_name, _} -> stat_name end, fn {_, value} -> value end)

    reductions_measurements =
      scenarios
      |> Enum.flat_map(fn scenario -> Map.to_list(scenario.reductions_data.statistics) end)
      |> Enum.group_by(fn {stat_name, _} -> stat_name end, fn {_, value} -> value end)

    memory_measurements =
      scenarios
      |> Enum.flat_map(fn
        %Scenario{memory_usage_data: %{statistics: nil}} ->
          []

        %Scenario{memory_usage_data: %{statistics: memory_usage_statistics}} ->
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
      memory: Memory.best(memory_average, strategy: scaling_strategy),
      reduction_count: Count.best(reductions_measurements.average, strategry: scaling_strategy)
    }
  end
end
