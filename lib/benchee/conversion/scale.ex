defmodule Benchee.Conversion.Scale do
  @moduledoc """
  Functions for scaling values to other units. Different domains handle
  this task differently, for example durations and counts.

  See `Benchee.Conversion.Count` and `Benchee.Conversion.Duration` for examples
  """

  @type unit :: atom
  @type scaled_number :: {number, unit}

  # In 1.3, this could be declared as `keyword`, but use a custom type so it
  # will also compile in 1.2
  @type options ::[{atom, atom}]

  @doc """
  Scales a number in a domain's base unit to an equivalent value in the best
  fit unit. Results are a `{number, unit}` tuple. See `Benchee.Conversion.Count` and
  `Benchee.Conversion.Duration` for examples
  """
  @callback scale(number) :: scaled_number

  @doc """
  Scales a number in a domain's base unit to an equivalent value in the
  specified unit. Results are a `{number, unit}` tuple. See
  `Benchee.Conversion.Count` and `Benchee.Conversion.Duration` for examples
  """
  @callback scale(number, unit) :: number

  @doc """
  Finds the best fit unit for a list of numbers in a domain's base unit.
  "Best fit" is the most common unit, or (in case of tie) the largest of the
  most common units.
  """
  @callback best(list, options) :: unit

  @doc """
  The magnitude of a unit, as a number.  See `Benchee.Conversion.Count`
  and `Benchee.Conversion.Duration` for examples
  """
  @callback magnitude(unit) :: number

  @doc """
  Returns the base_unit in which Benchee takes its measurements, which in
  general is the smallest supported unit.
  """
  @callback base_unit :: unit

  # Generic scaling functions

  def magnitude(units, unit) do
    units
    |> Map.fetch!(unit)
    |> Map.fetch!(:magnitude)
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
end
