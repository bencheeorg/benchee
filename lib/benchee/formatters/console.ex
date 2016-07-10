defmodule Benchee.Formatters.Console do
  @moduledoc """
  Formatter to transform the statistics output into a structure suitable for
  output through `IO.puts` on the console.
  """

  alias Benchee.Statistics

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
  iex> Benchee.Formatters.Console.format(%{statistics: jobs})
  ["\nName             ips        average    deviation         median\n",
  "My Job       5000.00       200.00μs    (±10.00%)       190.00μs"]

  ```

  """
  def format(%{statistics: job_stats}) do
    sorted_stats = Statistics.sort(job_stats)
    label_width = label_width job_stats
    [column_descriptors(label_width) | job_reports(sorted_stats, label_width)
      ++ comparison_report(sorted_stats, label_width)]
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

  defp job_reports(jobs, label_width) do
    Enum.map(jobs, fn(job) -> format_job job, label_width end)
  end

  defp format_job({name, %{average:       average,
                           ips:           ips,
                           std_dev_ratio: std_dev_ratio,
                           median:        median}
                         }, label_width) do
    "~*s~*.2f~*ts~*ts~*ts\n"
    |> :io_lib.format([-label_width, name, @ips_width, ips,
                       @average_width, average_out(average),
                       @deviation_width, deviation_out(std_dev_ratio),
                       @median_width, median_out(median)])
    |> to_string
  end

  defp average_out(average) do
    "~.#{float_precision(average)}f~ts"
    |> :io_lib.format([average, "μs"])
    |> to_string
  end

  defp float_precision(float) when float < 0.01, do: 5
  defp float_precision(float) when float < 0.1, do: 4
  defp float_precision(float) when float < 0.2, do: 3
  defp float_precision(_float), do: 2

  defp median_out(median) do
    "~.#{float_precision(median)}f~ts"
    |> :io_lib.format([median, "μs"])
    |> to_string
  end

  defp deviation_out(std_dev_ratio) do
    "(~ts~.2f%)"
    |> :io_lib.format(["±", std_dev_ratio * 100.0])
    |> to_string
  end

  defp comparison_report([_reference], _) do
    [] # No need for a comparison when only one benchmark was run
  end
  defp comparison_report([reference | other_jobs], label_width) do
    [
      comparison_descriptor,
      reference_report(reference, label_width) |
      comparisons(reference, label_width, other_jobs)
    ]
  end

  defp reference_report({name, %{ips: ips}}, label_width) do
    "~*s~*.2f\n"
    |> :io_lib.format([-label_width, name, @ips_width, ips])
    |> to_string
  end

  defp comparisons({_, reference_stats}, label_width, jobs_to_compare) do
    Enum.map jobs_to_compare, fn(job = {_, job_stats}) ->
      format_comparison(job, label_width, (reference_stats.ips / job_stats.ips))
    end
  end

  defp format_comparison({name, %{ips: ips}}, label_width, times_slower) do
    "~*s~*.2f - ~.2fx slower\n"
    |> :io_lib.format([-label_width, name, @ips_width, ips, times_slower])
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
