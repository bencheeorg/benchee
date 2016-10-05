defmodule Benchee.Conversion.Unit do
  defstruct [:magnitude, :short, :long]

@doc """
Fetches a unit's magnitude from a map of units
"""
def magnitude(units, unit) do
  units
  |> Map.fetch!(unit)
  |> Map.fetch!(:magnitude)
end


end
