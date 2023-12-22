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

  @doc """
  Formats in a more "human" way, one biggest unit at a time.

  So instead of 1.5h it says 1h 30min
  """
  @callback format_human(number) :: String.t()

  # Generic formatting functions

  @doc """
  Formats a unit value with specified label and separator
  """
  def format(number, label, separator) do
    separator = separator(label, separator)
    "#{number_format(number)}#{separator}#{label}"
  end

  defp number_format(number) when is_float(number) do
    number
    |> :erlang.float_to_list(decimals: float_precision(number))
    |> to_string
  end

  defp number_format(number) when is_integer(number) do
    to_string(number)
  end

  @doc """
  Formats a unit value in the domain described by `module`. The module should
  provide a `units/0` function that returns a Map like

      %{ :unit_name => %Benchee.Conversion.Unit{ ... } }

  Additionally, `module` may specify a `separator/0` function, which provides a
  custom separator string that will appear between the value and label in the
  formatted output. If no `separator/0` function exists, the default separator
  (a single space) will be used.

      iex> format({1.0, :kilobyte}, Benchee.Conversion.Memory)
      "1 KB"

  """
  def format({number, unit = %Unit{}}) do
    format(number, label(unit), separator())
  end

  def format({number, unit = %Unit{}}, _module) do
    format({number, unit})
  end

  def format({number, unit_atom}, module) do
    format({number, module.unit_for(unit_atom)})
  end

  def format(number, module) when is_number(number) do
    number
    |> module.scale()
    |> format
  end

  @doc """
  Human friendly duration format for time as a string.

  The output is a sequence of values and unit labels separated by a space.
  Only units whose value is non-zero are included in the output.
  The passed number is duration in the base unit - nanoseconds.
  """
  def format_human(0, module) do
    format(0, module)
  end

  def format_human(+0.0, module) do
    format(0, module)
  end

  def format_human(number, module) when is_number(number) do
    number
    |> split_into_place_values(module)
    |> Enum.map_join(" ", &format/1)
  end

  # Returns a list of place vaules with corresponding units for the `number`.
  # The output is sorted descending by magnitude of units and excludes tuples with place value 0.
  # Place values are `non_neg_integer` for non-base units,
  # however base unit may also be `float` becuase the decimals can't be split further.
  @spec split_into_place_values(number, module) :: [{number, Unit.t()}]
  defp split_into_place_values(number, module) do
    descending_units = units_descending(module)

    place_values(number, descending_units)
  end

  defp units_descending(module) do
    Enum.sort(module.units(), &(&1.magnitude >= &2.magnitude))
  end

  @spec place_values(number, [Unit.t()]) :: [{number, Unit.t()}]
  defp place_values(0, _units), do: []
  defp place_values(+0.0, _units), do: []

  # smalles unit, carries the decimal
  defp place_values(number, [base_unit = %Unit{magnitude: 1}]), do: [{number, base_unit}]

  defp place_values(number, [unit | units]) do
    integer_number = trunc(number)
    decimal_carry = number - integer_number
    int_carry = rem(integer_number, unit.magnitude)
    carry = decimal_carry + int_carry

    place_value = div(integer_number, unit.magnitude)

    case place_value do
      0 -> place_values(carry, units)
      place_value -> [{place_value, unit} | place_values(carry, units)]
    end
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
