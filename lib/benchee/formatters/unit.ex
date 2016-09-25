defmodule Benchee.Unit do
  @moduledoc """
  The specification for a `Benchee.Unit`, which describes how to format
  values in a given domain, for example durations or counts.

  See `Benchee.Unit.Count` and `Benchee.Unit.Duration` for examples
  """

  @type unit :: atom
  @type scaled_number :: {number, unit}

  # In 1.3, this could be declared as `keyword`, but use a custom type so it
  # will also compile in 1.2
  @type options ::[{atom, atom}]

  @doc """
  Scales a number in a domain's base unit to an equivalent value in the best
  fit unit. Results are a `{number, unit}` tuple. See `Benchee.Unit.Count` and
  `Benchee.Unit.Duration` for examples
  """
  @callback scale(number) :: scaled_number

  @doc """
  Scales a number in a domain's base unit to an equivalent value in the
  specified unit. Results are a `{number, unit}` tuple. See
  `Benchee.Unit.Count` and `Benchee.Unit.Duration` for examples
  """
  @callback scale(number, unit) :: scaled_number

  @doc """
  Formats a number as a string, with a unit label. See `Benchee.Unit.Count`
  and `Benchee.Unit.Duration` for examples
  """
  @callback format(number) :: String.t

  @doc """
  Finds the best fit unit for a list of numbers in a domain's base unit.
  "Best fit" is the most common unit, or (in case of tie) the largest of the
  most common units.
  """
  @callback best(list, options) :: unit

  @doc """
  The label for a given unit, as a String.  See `Benchee.Unit.Count`
  and `Benchee.Unit.Duration` for examples
  """
  @callback label(unit) :: String.t

  @doc """
  The magnitude of a unit, as a number.  See `Benchee.Unit.Count`
  and `Benchee.Unit.Duration` for examples
  """
  @callback magnitude(unit) :: number

  @doc """
  A string that appears between a value and a unit label when formatted as a
  String. For example, a space: `5.67 M` or an empty string: `5.67M`
  """
  @callback separator :: String.t

  @doc """
  Returns the base_unit in which Benchee takes its measurements, which in
  general is the smallest supported unit.
  """
  @callback base_unit :: unit

  # Common functions used by unit types
  defmodule Common do
    @moduledoc false

    @doc """
    Formats a unit value with specified label and separator
    """
    def format({count, unit}, label, separator) do
      separator = separator(label, separator)
      "~.#{float_precision(count)}f~ts~ts"
      |> :io_lib.format([count, separator, label])
      |> to_string
    end

    @doc """
    Formats a unit value with the label and separator supplied by `module`. The
    specified module should provide `label/1` and `separator/1` functions
    """
    def format({count, unit}, module) do
      format({count, unit}, module.label(unit), module.separator)
    end

    def format(number, module) do
      number
      |> module.scale
      |> format(module)
    end

    def magnitude(units, unit) do
      units
      |> Map.fetch!(unit)
      |> Map.fetch!(:magnitude)
    end

    def label(units, unit) do
      units
      |> Map.fetch!(unit)
      |> Map.fetch!(:short)
    end

    def best_unit(list, module, opts) do
      case Keyword.get(opts, :strategy, :best) do
        :best     -> best_unit(list, module)
        :largest  -> largest_unit(list, module)
        :smallest -> smallest_unit(list, module)
        :base     -> module.base_unit
      end
    end

    # Finds the most common unit in the list. In case of tie, chooses the
    # largest of the most common
    defp best_unit(list, module) do
      list
      |> Enum.map(fn n -> scale_unit(n, module) end)
      |> Enum.group_by(fn unit -> unit end)
      |> Enum.map(fn {unit, occurrences} -> {unit, length(occurrences)} end)
      |> Enum.sort(fn unit, freq -> by_frequency_and_magnitude(unit, freq, module) end)
      |> hd
      |> elem(0)
    end

    # Finds the smallest unit in the list
    defp smallest_unit(list, module) do
      list
      |> Enum.map(fn n -> scale_unit(n, module) end)
      |> Enum.min_by(&module.magnitude/1)
    end

    # Finds the largest unit in the list
    defp largest_unit(list, module) do
      list
      |> Enum.map(fn n -> scale_unit(n, module) end)
      |> Enum.max_by(&module.magnitude/1)
    end

    defp scale_unit(count, module) do
      {_, unit} = module.scale(count)
      unit
    end

    # Sorts two elements first by total, then by magnitude of the unit in case
    # of tie
    defp by_frequency_and_magnitude({unit_a, frequency}, {unit_b, frequency}, module) do
      module.magnitude(unit_a) > module.magnitude(unit_b)
    end
    defp by_frequency_and_magnitude({_, frequency_a}, {_, frequency_b}, _module) do
      frequency_a > frequency_b
    end

    # Returns the separator, or an empty string if there isn't a label
    defp separator(label, separator) do
      case label do
        "" -> ""
        _  -> separator
      end
    end

    defp float_precision(float) when float < 0.01, do: 5
    defp float_precision(float) when float < 0.1, do: 4
    defp float_precision(float) when float < 0.2, do: 3
    defp float_precision(_float), do: 2
  end
end
