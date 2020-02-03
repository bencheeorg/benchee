defmodule Benchee.Formatters.Console do
  @moduledoc """
  Formatter to print out the results of benchmarking suite to the console.

  Example:

      Name                  ips        average  deviation         median         99th %
      flat_map           2.40 K      417.00 μs     ±9.40%      411.45 μs      715.21 μs
      map.flatten        1.24 K      806.89 μs    ±16.62%      768.02 μs     1170.67 μs

      Comparison:
      flat_map           2.40 K
      map.flatten        1.24 K - 1.93x slower

      Memory usage statistics:

      Name           Memory usage
      flat_map          624.97 KB
      map.flatten       781.25 KB - 1.25x memory usage

      **All measurements for memory usage were the same**

      Reduction count statistics:

      Name              average  deviation      median      99th %
      flat_map           417.00      ±9.40      411.45      715.21
      map.flatten        806.89     ±16.62      768.02     1170.67

      Comparison:
      flat_map           417.00
      map.flatten        806.89 - 1.93x more reductions
  """

  @behaviour Benchee.Formatter

  alias Benchee.Suite
  alias Benchee.Formatters.Console.{Memory, Reductions, RunTime}

  @doc """
  Formats the benchmark statistics to a report suitable for output on the CLI.

  Returns a list of lists, where each list element is a group belonging to one
  specific input. So if there only was one (or no) input given through `:inputs`
  then there's just one list inside.

  ## Examples

  ```
  iex> scenarios = [
  ...>   %Benchee.Scenario{
  ...>     name: "My Job", input_name: "My input", run_time_data: %Benchee.CollectionData{
  ...>       statistics: %Benchee.Statistics{
  ...>         average: 200.0,
  ...>         ips: 5000.0,
  ...>         std_dev_ratio: 0.1,
  ...>         median: 190.0,
  ...>         percentiles: %{99 => 300.1},
  ...>         sample_size: 200
  ...>       }
  ...>     },
  ...>     memory_usage_data: %Benchee.CollectionData{statistics: %Benchee.Statistics{}}
  ...>   },
  ...>   %Benchee.Scenario{
  ...>     name: "Job 2", input_name: "My input", run_time_data: %Benchee.CollectionData{
  ...>       statistics: %Benchee.Statistics{
  ...>         average: 400.0,
  ...>         ips: 2500.0,
  ...>         std_dev_ratio: 0.2,
  ...>         median: 390.0,
  ...>         percentiles: %{99 => 500.1},
  ...>         sample_size: 200
  ...>       }
  ...>     },
  ...>     memory_usage_data: %Benchee.CollectionData{statistics: %Benchee.Statistics{}}
  ...>   }
  ...> ]
  iex> suite = %Benchee.Suite{
  ...>   scenarios: scenarios,
  ...>   configuration: %Benchee.Configuration{
  ...>     unit_scaling: :best,
  ...>   }
  ...> }
  iex> Benchee.Formatters.Console.format(suite, %{comparison: false, extended_statistics: false})
  [["\n##### With input My input #####", "\nName             ips        average  deviation         median         99th %\n",
  "My Job           5 K         200 ns    ±10.00%         190 ns      300.10 ns\n",
  "Job 2         2.50 K         400 ns    ±20.00%         390 ns      500.10 ns\n"]]

  ```

  """
  @impl true
  @spec format(Suite.t(), map) :: [any]
  def format(%Suite{scenarios: scenarios, configuration: config}, options \\ %{}) do
    config =
      config
      |> Map.take([:unit_scaling, :title])
      |> Map.merge(options)

    scenarios
    |> Enum.reduce([], &update_grouped_list/2)
    |> Enum.map(fn {input, scenarios} ->
      generate_output(scenarios, config, input)
    end)
  end

  # Normally one would prepend to lists and not append. In this case this lead to 2
  # `Enum.reverse` scattered around. As these lists are usually very small (mostly less
  # than 10 elements) I opted for `++` here.
  defp update_grouped_list(scenario, grouped_scenarios) do
    case List.keyfind(grouped_scenarios, scenario.input_name, 0) do
      {_, group} ->
        new_tuple = {scenario.input_name, group ++ [scenario]}
        List.keyreplace(grouped_scenarios, scenario.input_name, 0, new_tuple)

      _ ->
        grouped_scenarios ++ [{scenario.input_name, [scenario]}]
    end
  end

  @doc """
  Takes the output of `format/1` and writes that to the console.
  """
  @impl true
  @spec write(any, map) :: :ok | {:error, String.t()}
  def write(output, _options \\ %{}) do
    IO.write(output)
  rescue
    _ -> {:error, "Unknown Error"}
  end

  defp generate_output(scenarios, config, input) do
    [
      suite_header(input, config)
      | RunTime.format_scenarios(scenarios, config) ++
          Memory.format_scenarios(scenarios, config) ++
          Reductions.format_scenarios(scenarios, config)
    ]
  end

  defp suite_header(input, config) do
    "#{title_header(config)}#{input_header(input)}"
  end

  defp title_header(%{title: nil}), do: ""
  defp title_header(%{title: title}), do: "\n*** #{title} ***\n"

  @no_input_marker Benchee.Benchmark.no_input()
  defp input_header(input) when input == @no_input_marker, do: ""
  defp input_header(input), do: "\n##### With input #{input} #####"
end
