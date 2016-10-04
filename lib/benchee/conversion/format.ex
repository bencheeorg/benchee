defmodule Benchee.Conversion.Format do
  @moduledoc """
  Functions for formatting values and their unit labels. Different domains
  handle this task differently, for example durations and counts.

  See `Benchee.Conversion.Count` and `Benchee.Conversion.Duration` for examples
  """
  @type unit :: atom

  @doc """
  Formats a number as a string, with a unit label. See `Benchee.Conversion.Count`
  and `Benchee.Conversion.Duration` for examples
  """
  @callback format(number) :: String.t

  @doc """
  The label for a given unit, as a String.  See `Benchee.Conversion.Count`
  and `Benchee.Conversion.Duration` for examples
  """
  @callback label(unit) :: String.t

  @doc """
  A string that appears between a value and a unit label when formatted as a
  String. For example, a space: `5.67 M` or an empty string: `5.67M`
  """
  @callback separator :: String.t
end
