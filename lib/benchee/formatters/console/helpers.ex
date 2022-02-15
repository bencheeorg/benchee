defmodule Benchee.Formatters.Console.Helpers do
  @moduledoc false

  # These are common functions shared between the formatting of the run time and
  # memory usage statistics.

  alias Benchee.Conversion.{Count, DeviationPercent, Format, Scale, Unit}
  alias Benchee.Scenario
  alias Benchee.Statistics

  @type unit_per_statistic :: %{atom => Unit.t()}

  # Length of column header
  @default_label_width 4

  @spec mode_out(Statistics.mode(), Benchee.Conversion.Unit.t()) :: String.t()
  def mode_out(modes, _run_time_unit) when is_nil(modes) do
    "None"
  end

  def mode_out(modes, run_time_unit) when is_list(modes) do
    Enum.map_join(modes, ", ", fn mode -> unit_output(mode, run_time_unit) end)
  end

  def mode_out(mode, run_time_unit) when is_number(mode) do
    unit_output(mode, run_time_unit)
  end

  defp unit_output(value, unit) do
    Format.format({Scale.scale(value, unit), unit})
  end

  @spec label_width([Scenario.t()]) :: number
  def label_width(scenarios) do
    max_label_width =
      scenarios
      |> Enum.map(fn scenario -> String.length(scenario.name) end)
      |> Stream.concat([@default_label_width])
      |> Enum.max()

    max_label_width + 1
  end

  @spec count_output(number, Count.units()) :: binary
  def count_output(count, unit) do
    Count.format({Count.scale(count, unit), unit})
  end

  @spec deviation_output(number) :: binary
  def deviation_output(std_dev_ratio) do
    DeviationPercent.format(std_dev_ratio)
  end

  @spec descriptor(String.t()) :: String.t()
  def descriptor(header_str), do: "\n#{header_str}: \n"

  def format_comparison(
        name,
        statistics,
        display_value,
        comparison_name,
        display_unit,
        label_width,
        column_width
      ) do
    "~*s~*s ~ts"
    |> :io_lib.format([
      -label_width,
      name,
      column_width,
      display_value,
      comparison_display(statistics, comparison_name, display_unit)
    ])
    |> to_string
  end

  defp comparison_display(%Statistics{relative_more: nil, absolute_difference: nil}, _, _), do: ""

  defp comparison_display(statistics, comparison_name, unit) do
    "- #{comparison_text(statistics, comparison_name)} #{absolute_difference_text(statistics, unit)}\n"
  end

  defp comparison_text(%Statistics{relative_more: :infinity}, name), do: "∞ x #{name}"
  defp comparison_text(%Statistics{relative_more: nil}, _), do: "N/A"

  defp comparison_text(statistics, comparison_name) do
    "~.2fx ~s"
    |> :io_lib.format([statistics.relative_more, comparison_name])
    |> to_string
  end

  defp absolute_difference_text(statistics, unit) do
    formatted_value = Format.format({Scale.scale(statistics.absolute_difference, unit), unit})

    if statistics.absolute_difference >= 0 do
      "+#{formatted_value}"
    else
      formatted_value
    end
  end
end
