defmodule Benchee.Units do
  @one_billion 1_000_000_000
  @one_million 1_000_000
  @one_thousand 1_000

  def scale_count(count) when count >= @one_billion,  do: {count / @one_billion, :billion}
  def scale_count(count) when count >= @one_million,  do: {count / @one_million, :million}
  def scale_count(count) when count >= @one_thousand, do: {count / @one_thousand, :thousand}
  def scale_count(count), do: {count, :one}

  @spec format_count(number) :: String.t
  def format_count(count) do
    count
    |> scale_count
    |> do_format_count
  end

  defp do_format_count({count, unit}) do
    "~.#{float_precision(count)}f~ts"
    |> :io_lib.format([count, unit_label(unit)])
    |> to_string
  end

  def float_precision(float) when float < 0.01, do: 5
  def float_precision(float) when float < 0.1, do: 4
  def float_precision(float) when float < 0.2, do: 3
  def float_precision(_float), do: 2

  def unit_label(:billion), do: "B"
  def unit_label(:million), do: "M"
  def unit_label(:thousand), do: "K"
  def unit_label(_), do: ""
end
