defmodule Benchee.Conversion.Format do
  @moduledoc """
  Functions for formatting values and their unit labels. Different domains
  handle this task differently, for example durations and counts.

  See `Benchee.Conversion.Count` and `Benchee.Conversion.Duration` for examples.
  """

  alias Benchee.Conversion.Unit

  @doc """
  Formats a number as a string, with a unit label. See `Benchee.Conversion.Count`
  and `Benchee.Conversion.Duration` for examples
  """
  @callback format(number) :: String.t()

  # Generic formatting functions

  @doc """
  Formats a unit value with specified label and separator
  """
  def format(count, label, separator) do
    separator = separator(label, separator)
    "#{number_format(count)}#{separator}#{label}"
  end

  defp number_format(count) do
    count
    |> :erlang.float_to_list(decimals: float_precision(count))
    |> to_string
  end

  @doc """
  Formats a unit value in the domain described by `module`. The module should
  provide a `units/0` function that returns a Map like

      %{ :unit_name => %Benchee.Conversion.Unit{ ... } }

  Additionally, `module` may specify a `separator/0` function, which provides a
  custom separator string that will appear between the value and label in the
  formatted output. If no `separator/0` function exists, the default separator
  (a single space) will be used.

      iex> Benchee.Conversion.Format.format({1.0, :kilobyte}, Benchee.Conversion.Memory)
      "1 KB"

  """
  def format({count, unit = %Unit{}}) do
    format(count, label(unit), separator())
  end

  def format({count, unit = %Unit{}}, _module) do
    format({count, unit})
  end

  def format({count, unit_atom}, module) do
    format({count, module.unit_for(unit_atom)})
  end

  def format(number, module) do
    number
    |> module.scale()
    |> format
  end

  @default_separator " "
  # should we need it again, a customer separator could be returned
  # per module here
  defp separator do
    @default_separator
  end

  # Returns the separator, or an empty string if there isn't a label
  defp separator(label, _separator) when label == "" or label == nil, do: ""
  defp separator(_label, separator), do: separator

  # Fetches the label for the given unit
  defp label(%Unit{label: label}) do
    label
  end

  defp float_precision(float) when trunc(float) == float, do: 0
  defp float_precision(float) when float < 0.01, do: 5
  defp float_precision(float) when float < 0.1, do: 4
  defp float_precision(float) when float < 0.2, do: 3
  defp float_precision(_float), do: 2
end
