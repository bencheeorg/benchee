defmodule Benchee.Formatters.Console do
  @moduledoc """
  Formatter to transform the statistics output into a structure suitable for
  output through `IO.puts` on the console.
  """

  alias Benchee.Statistics

  @label_width 30
  @ips_width 15
  @average_width 15
  @deviation_width 15

  @doc """
  Formats the benchmark statistics to a report suitable for output on the CLI.

  ## Examples

  ```
  iex> jobs = [{"My Job", %{average: 200.0, ips: 5000.0, std_dev_ratio: 0.1, median: 190.0}}]
  iex> Benchee.Formatters.Console.format(jobs)
  ["\nName                          ips            average        deviation      median\n",
  "My Job                        5000.00        200.00μs       (±10.00%)      190.00μs\n"]

  ```

  """
  def format(jobs) do
    sorted = Statistics.sort(jobs)
    [column_descriptors | job_reports(sorted) ++ comparison_report(sorted)]
  end

  defp column_descriptors do
    "\n~*s~*s~*s~*s~s\n"
    |> :io_lib.format([-@label_width, "Name", -@ips_width, "ips",
                       -@average_width, "average",
                       -@deviation_width, "deviation", "median"])
    |> to_string
  end

  defp job_reports(jobs) do
    Enum.map(jobs, &format_job/1)
  end

  defp format_job({name, %{average:       average,
                           ips:           ips,
                           std_dev_ratio: std_dev_ratio,
                           median:         median}}) do
    "~*s~*.2f~*ts~*ts~ts\n"
    |> :io_lib.format([-@label_width, name, -@ips_width, ips,
                       -@average_width, average_out(average),
                       -@deviation_width, deviation_out(std_dev_ratio),
                       median_out(median)])
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
  defp float_precision(float), do: 2

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

  defp comparison_report([_reference]) do
    [] # No need for a comparison when only one benchmark was run
  end

  defp comparison_report([reference | other_jobs]) do
    report = [reference_report(reference) | comparisons(reference, other_jobs)]
    [comparison_descriptor | report]
  end

  defp reference_report({name, %{ips: ips}}) do
    "~*s~.2f\n"
    |> :io_lib.format([-@label_width, name, ips])
    |> to_string
  end

  defp comparisons({_, reference_stats}, jobs_to_compare) do
    Enum.map jobs_to_compare, fn(job = {_, job_stats}) ->
      # IO.inspect {reference, job}
      format_comparison(job, (reference_stats.ips / job_stats.ips))
    end
  end

  defp format_comparison({name, %{ips: ips}}, times_slower) do
    "~*s~*.2f - ~.2fx slower\n"
    |> :io_lib.format([-@label_width, name, -@ips_width, ips, times_slower])
    |> to_string
  end

  defp comparison_descriptor do
    "\nComparison: \n"
  end
end
