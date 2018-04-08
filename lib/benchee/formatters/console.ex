defmodule Benchee.Formatters.Console do
  @moduledoc """
  Formatter to transform the statistics output into a structure suitable for
  output through `IO.write` on the console.
  """

  use Benchee.Formatter

  alias Benchee.{Statistics, Suite, Configuration}
  alias Benchee.Formatters.Console.{Memory, RunTime}

  @doc """
  Formats the benchmark statistics to a report suitable for output on the CLI.

  Returns a list of lists, where each list element is a group belonging to one
  specific input. So if there only was one (or no) input given through `:inputs`
  then there's just one list inside.

  ## Examples

  ```
  iex> scenarios = [
  ...>   %Benchee.Benchmark.Scenario{
  ...>     name: "My Job", input_name: "My input", run_time_statistics: %Benchee.Statistics{
  ...>       average: 200.0,
  ...>       ips: 5000.0,
  ...>       std_dev_ratio: 0.1,
  ...>       median: 190.0,
  ...>       percentiles: %{99 => 300.1},
  ...>       sample_size: 200
  ...>     },
  ...>     memory_usage_statistics: %Benchee.Statistics{}
  ...>   },
  ...>   %Benchee.Benchmark.Scenario{
  ...>     name: "Job 2", input_name: "My input", run_time_statistics: %Benchee.Statistics{
  ...>       average: 400.0,
  ...>       ips: 2500.0,
  ...>       std_dev_ratio: 0.2,
  ...>       median: 390.0,
  ...>       percentiles: %{99 => 500.1},
  ...>       sample_size: 200
  ...>     },
  ...>     memory_usage_statistics: %Benchee.Statistics{}
  ...>   }
  ...> ]
  iex> suite = %Benchee.Suite{
  ...>   scenarios: scenarios,
  ...>   configuration: %Benchee.Configuration{
  ...>     formatter_options: %{
  ...>       console: %{comparison: false, extended_statistics: false}
  ...>     },
  ...>     unit_scaling: :best,
  ...>   }
  ...> }
  iex> Benchee.Formatters.Console.format(suite)
  [["\n##### With input My input #####", "\nName             ips        average  deviation         median         99th %\n",
  "My Job           5 K         200 μs    ±10.00%         190 μs      300.10 μs\n",
  "Job 2         2.50 K         400 μs    ±20.00%         390 μs      500.10 μs\n"]]

  ```

  """
  @spec format(Suite.t()) :: [any]
  def format(%Suite{scenarios: scenarios, configuration: config}) do
    config = console_configuration(config)

    scenarios
    |> Enum.group_by(fn scenario -> scenario.input_name end)
    |> Enum.map(fn {input, scenarios} ->
      scenarios
      |> Statistics.sort()
      |> generate_output(config, input)
    end)
  end

  @doc """
  Takes the output of `format/1` and writes that to the console.
  """
  @spec write(any) :: :ok | {:error, String.t()}
  def write(output) do
    IO.write(output)
  rescue
    _ -> {:error, "Unknown Error"}
  end

  defp console_configuration(config) do
    %Configuration{
      formatter_options: %{console: console_config},
      unit_scaling: scaling_strategy
    } = config

    if Map.has_key?(console_config, :unit_scaling), do: warn_unit_scaling()
    Map.put(console_config, :unit_scaling, scaling_strategy)
  end

  defp warn_unit_scaling do
    IO.puts(
      "unit_scaling is now a top level configuration option, avoid passing it as a formatter option."
    )
  end

  defp generate_output(scenarios, config, input) do
    [
      input_header(input) |
      RunTime.format_scenarios(scenarios, config) ++
      Memory.format_scenarios(scenarios, config)
    ]
  end

  @no_input_marker Benchee.Benchmark.no_input()
  defp input_header(input) when input == @no_input_marker, do: ""
  defp input_header(input), do: "\n##### With input #{input} #####"
end
