defmodule Benchee.Formatters.Console.Helpers do
  @moduledoc """
  These are common functions shared between the formatting of the run time and
  memory usage statistics.
  """

  alias Benchee.Statistics
  alias Benchee.Conversion.{Count, Duration, Unit, DeviationPercent}

  @type unit_per_statistic :: %{atom => Unit.t()}

  # Length of column header
  @default_label_width 4

  @spec mode_out(Statistics.mode(), Benchee.Conversion.Unit.t()) :: String.t()
  def mode_out(modes, _run_time_unit) when is_nil(modes) do
    "None"
  end

  def mode_out(modes, run_time_unit) when is_list(modes) do
    Enum.map_join(modes, ", ", fn mode -> run_time_out(mode, run_time_unit) end)
  end

  def mode_out(mode, run_time_unit) when is_number(mode) do
    run_time_out(mode, run_time_unit)
  end

  def label_width(scenarios) do
    max_label_width =
      scenarios
      |> Enum.map(fn scenario -> String.length(scenario.name) end)
      |> Stream.concat([@default_label_width])
      |> Enum.max()

    max_label_width + 1
  end

  def ips_out(ips, unit) do
    Count.format({Count.scale(ips, unit), unit})
  end

  def run_time_out(run_time, unit) do
    Duration.format({Duration.scale(run_time, unit), unit})
  end

  def deviation_out(std_dev_ratio) do
    DeviationPercent.format(std_dev_ratio)
  end

  @spec descriptor(String.t()) :: String.t()
  def descriptor(header_str), do: "\n#{header_str}: \n"
end
