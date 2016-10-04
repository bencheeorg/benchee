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
  @callback scale(number, unit) :: scaled_number

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
end
