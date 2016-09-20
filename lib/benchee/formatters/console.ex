defmodule Benchee.Formatters.Console do
  @moduledoc """
  Formatter to transform the statistics output into a structure suitable for
  output through `IO.puts` on the console.
  """

  alias Benchee.Statistics
  alias Benchee.Unit.{Count, Duration}

  @default_label_width 4 # Length of column header
  @ips_width 13
  @average_width 15
  @deviation_width 13
  @median_width 15

  @doc """
  Formats the benchmark statistis using `Benchee.Formatters.Console.format/1`
  and then prints it out directly to the console using `IO.puts/2`
  """
  def output(suite) do
    suite
    |> format
    |> IO.puts
  end

  @doc """
  Formats the benchmark statistics to a report suitable for output on the CLI.

  ## Examples

  ```
  iex> jobs = %{"My Job" => %{average: 200.0, ips: 5000.0, std_dev_ratio: 0.1, median: 190.0}}
  iex> Benchee.Formatters.Console.format(%{statistics: jobs, config: %{print: %{comparison: false}}})
  ["\nName             ips        average    deviation         median\n",
  "My Job        5.00 K      200.00 μs    (±10.00%)      190.00 μs"]

  ```

  """
  def format(%{statistics: job_stats, config: config}) do
    sorted_stats = Statistics.sort(job_stats)
    units = units(sorted_stats)
    label_width = label_width job_stats
    [column_descriptors(label_width) | job_reports(sorted_stats, units, label_width)
      ++ comparison_report(sorted_stats, units, label_width, config)]
    |> remove_last_blank_line
  end

  defp column_descriptors(label_width) do
    "\n~*s~*s~*s~*s~*s\n"
    |> :io_lib.format([-label_width, "Name", @ips_width, "ips",
                       @average_width, "average",
                       @deviation_width, "deviation", @median_width, "median"])
    |> to_string
  end

  defp label_width(jobs) do
    max_label_width = jobs
      |> Enum.map(fn({job_name, _}) -> String.length(job_name) end)
      |> Stream.concat([@default_label_width])
      |> Enum.max
    max_label_width + 1
  end

  defp job_reports(jobs, units, label_width) do
    Enum.map(jobs, fn(job) -> format_job job, units, label_width end)
  end

  defp units(jobs) do
    # Produces a map like
    #   %{run_time: [12345, 15431, 13222], ips: [1, 2, 3]}
    collected_values =
      jobs
      |> Enum.flat_map(fn({_name, job}) -> Map.to_list(job) end)
      # TODO: Simplify when dropping support for 1.2
      # For compatibility with Elixir 1.2. In 1.3, the following group-reduce-map
      # can b replaced by a single call to `group_by/3`
      #   Enum.group_by(fn({stat_name, _}) -> stat_name end, fn({_, value}) -> value end)
      |> Enum.group_by(fn({stat_name, _value}) -> stat_name end)
      |> Enum.reduce(%{}, fn({stat_name, occurrences}, acc) ->
        Map.put(acc, stat_name, Enum.map(occurrences, fn({_stat_name, value}) -> value end))
      end)

    %{
      run_time: Duration.best(collected_values.average),
      ips:      Count.best(collected_values.ips),
    }
  end

  defp format_job({name, %{average:       average,
                           ips:           ips,
                           std_dev_ratio: std_dev_ratio,
                           median:        median}
                         },
                         %{run_time:      run_time_unit,
                           ips:           ips_unit,
                         }, label_width) do
    "~*s~*ts~*ts~*ts~*ts\n"
    |> :io_lib.format([-label_width, name, @ips_width, ips_out(ips, ips_unit),
                       @average_width, run_time_out(average, run_time_unit),
                       @deviation_width, deviation_out(std_dev_ratio),
                       @median_width, run_time_out(median, run_time_unit)])
    |> to_string
  end

  defp ips_out(ips, unit) do
    Count.format(Count.scale(ips, unit))
  end

  defp run_time_out(average, unit) do
    Duration.format(Duration.scale(average, unit))
  end

  defp deviation_out(std_dev_ratio) do
    "(~ts~.2f%)"
    |> :io_lib.format(["±", std_dev_ratio * 100.0])
    |> to_string
  end

  defp comparison_report([_reference], _, _, _config) do
    [] # No need for a comparison when only one benchmark was run
  end
  defp comparison_report(_, _, _, %{console: %{comparison: false}}) do
    []
  end
  defp comparison_report([reference | other_jobs], units, label_width, _config) do
    [
      comparison_descriptor,
      reference_report(reference, units, label_width) |
      comparisons(reference, units, label_width, other_jobs)
    ]
  end

  defp reference_report({name, %{ips: ips}}, %{ips: ips_unit}, label_width) do
    "~*s~*s\n"
    |> :io_lib.format([-label_width, name, @ips_width, ips_out(ips, ips_unit)])
    |> to_string
  end

  defp comparisons({_, reference_stats}, units, label_width, jobs_to_compare) do
    Enum.map jobs_to_compare, fn(job = {_, job_stats}) ->
      format_comparison(job, units, label_width, (reference_stats.ips / job_stats.ips))
    end
  end

  defp format_comparison({name, %{ips: ips}}, %{ips: ips_unit}, label_width, times_slower) do
    "~*s~*s - ~.2fx slower\n"
    |> :io_lib.format([-label_width, name, @ips_width, ips_out(ips, ips_unit), times_slower])
    |> to_string
  end

  defp comparison_descriptor do
    "\nComparison: \n"
  end

  defp remove_last_blank_line([head]) do
    [String.rstrip(head)]
  end
  defp remove_last_blank_line([head | tail]) do
    [head | remove_last_blank_line(tail)]
  end

end
