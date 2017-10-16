defmodule Benchee.Conversion do
  @moduledoc """
  Integration of the conversion of multiple units with benchee.

  Can be used by plugins to use benche unit scaling logic.
  """

  alias Benchee.Conversion.{Duration, Count}

  @doc """
  Takes scenarios and a given scaling_strategy, returns the best unit for
  run_time and ips, according to the scaling_strategy, in a map.

  The units can then be passed on to the appropriate `format` calls to format
  the output of arbitrary values with the right unit.

  ## Examples

      iex> statistics = %Benchee.Statistics{average: 1000.0, ips: 1000.0}
      iex> scenario = %Benchee.Benchmark.Scenario{run_time_statistics: statistics}
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
                  }
      }
  """
  def units(scenarios, scaling_strategy) do
    # Produces a map like
    #   %{run_time: [12345, 15431, 13222], ips: [1, 2, 3]}
    measurements =
      scenarios
      |> Enum.flat_map(fn(scenario) ->
           Map.to_list(scenario.run_time_statistics)
         end)
      |> Enum.group_by(fn({stat_name, _}) -> stat_name end,
                       fn({_, value}) -> value end)

    %{
      run_time: Duration.best(measurements.average, strategy: scaling_strategy),
      ips:      Count.best(measurements.ips, strategy: scaling_strategy),
    }
  end
end
