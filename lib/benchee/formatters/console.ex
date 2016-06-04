defmodule Benchee.Formatters.Console do
  @moduledoc """
  Formatter to transform the statistics output into a structure suitable for
  output through `IO.puts` on the console.
  """

  alias Benchee.Statistics

  @label_width 30
  @ips_width 15
  @average_width 15

  @doc """
  Formats the benchmark statistics to a report suitable for output on the CLI.

  ## Examples

  ```
  iex> jobs = [{"My Job", %{average: 200.0, ips: 5000.0, std_dev_ratio: 0.1}}]
  iex> Benchee.Formatters.Console.format(jobs)
  ["\nName                          ips            average        deviation\n",
  "My Job                        5000.00        200.00μs       (±10.00%)\n"]

  ```

  """
  def format(jobs) do
    [column_descriptors | job_reports(jobs)]
  end

  defp column_descriptors do
    "\n~*s~*s~*s~s\n"
    |> :io_lib.format([-@label_width, "Name", -@ips_width, "ips",
                       -@average_width, "average", "deviation"])
    |> to_string
  end

  defp job_reports(jobs) do
    jobs
    |> Statistics.sort
    |> Enum.map(&format_job/1)
  end

  defp format_job({name, %{average:       average,
                           ips:           ips,
                           std_dev_ratio: std_dev_ratio}}) do
    "~*s~*.2f~*ts~ts\n"
    |> :io_lib.format([-@label_width, name, -@ips_width, ips,
                       -@average_width, average_out(average),
                       deviation_out(std_dev_ratio)])
    |> to_string
  end

  defp average_out(average) do
    "~.2f~ts"
    |> :io_lib.format([average, "μs"])
    |> to_string
  end

  defp deviation_out(std_dev_ratio) do
    "(~ts~.2f%)"
    |> :io_lib.format(["±", std_dev_ratio * 100.0])
    |> to_string
  end
end
