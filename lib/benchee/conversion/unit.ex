defmodule Benchee.Conversion.Unit do
  defstruct [:magnitude, :short, :long]

  @doc """
  The magnitude of the given unit. Requires that `module` implements `units/0`,
  and that `unit` is one of `module`'s units

  ## Examples

      iex> Benchee.Conversion.Unit.magnitude(Benchee.Conversion.Duration, :millisecond)
      1000

      iex> Benchee.Conversion.Unit.magnitude(Benchee.Conversion.Duration, :microsecond)
      1

      iex> Benchee.Conversion.Unit.magnitude(Benchee.Conversion.Count, :million)
      1000000

      iex> Benchee.Conversion.Unit.magnitude(Benchee.Conversion.Count, :one)
      1


  """
  def magnitude(module, unit) do
    fetch_nested_unit_field(module, unit, :magnitude)
  end

  @doc """
  The label for the given unit. Requires that `module` implements `units/0`,
  and that `unit` is one of `module`'s units

  ## Examples

      iex> Benchee.Conversion.Unit.label(Benchee.Conversion.Count, :million)
      "M"

      iex> Benchee.Conversion.Count.label(Benchee.Conversion.Count, :one)
      ""

      iex> Benchee.Conversion.Count.label(Benchee.Conversion.Duration, :millisecond)
      "ms"

      iex> Benchee.Conversion.Count.label(Benchee.Conversion.Duration, :microsecond)
      "μs"

  """
  def label(module, unit) do
    fetch_nested_unit_field(module, unit, :short)
  end

  # Fetches the value of `field` from the `unit` in module's Map of units, `units/0`
  defp fetch_nested_unit_field(module, unit, field) do
    module.units()
    |> Map.fetch!(unit)
    |> Map.fetch!(field)
  end
end
