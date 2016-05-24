defmodule Benchee.Formatters.String do
  @label_width 30
  @ips_width 15
  @average_width 15
  @deviation_width 15

  @doc """
  Formats the benchmark statistics to a report suitable for an output on the CLI.
  """
  def format(%{jobs: jobs}) do
    [column_descriptors | job_reports(jobs)]
  end

  defp column_descriptors do
    "~*s~*s~*s~*s\n"
    |> :io_lib.format([-@label_width, "Name", -@ips_width, "ips",
                       -@average_width, "average", -@deviation_width, "deviation"])
  end

  defp job_reports(jobs) do
    Enum.map jobs, fn(%{name: name, run_times: times}) ->
      %{average:      average,
        ips:          ips,
        std_dev_ratio: std_dev_ratio} = Benchee.Statistics.statistics(times)

      "~*s~*.2f~*ts~*ts\n"
      |> :io_lib.format([-@label_width, name, -@ips_width, ips,
                         -@average_width, average_out(average),
                         -@deviation_width, deviation_out(std_dev_ratio)])
    end
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
