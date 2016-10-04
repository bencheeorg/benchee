defmodule Benchee.Unit do
  @type unit :: atom

  # Common functions used by unit types
  defmodule Common do
    @moduledoc false

    @doc """
    Formats a unit value with specified label and separator
    """
    def format({count, _unit}, label, separator) do
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
        :none     -> module.base_unit
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
