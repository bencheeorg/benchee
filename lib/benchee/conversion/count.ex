defmodule Benchee.Conversion.Count do
  @moduledoc """
  Unit scaling for counts, such that 1000000 can be converted to 1 Million.
  """

  alias Benchee.Conversion.{Format, Scale, Unit}

  @behaviour Scale
  @behaviour Format

  @one_billion 1_000_000_000
  @one_million 1_000_000
  @one_thousand 1_000

  @units %{
    billion:  %Unit{
                magnitude: @one_billion,
                short: "B",
                long: "Billion"
              },
    million:  %Unit{
                magnitude: @one_million,
                short: "M",
                long: "Million"
              },
    thousand: %Unit{
                magnitude: @one_thousand,
                short: "K",
                long: "Thousand"
              },
    one:      %Unit{
                magnitude: 1,
                short: "",
                long: ""
              },
  }

  @doc """
  Units of count, in powers of 1_000: :one, :thousand, :million, :billion
  """
  def units, do: @units

  @doc """
  Scales a value representing a count in ones into a larger unit if appropriate

  ## Examples

      iex> Benchee.Conversion.Count.scale(4_321.09)
      {4.32109, :thousand}

      iex> Benchee.Conversion.Count.scale(0.0045)
      {0.0045, :one}

  """
  def scale(count) when count >= @one_billion do
    scale_with_unit(count, :billion)
  end
  def scale(count) when count >= @one_million do
    scale_with_unit(count, :million)
  end
  def scale(count) when count >= @one_thousand do
    scale_with_unit(count, :thousand)
  end
  def scale(count) do
    scale_with_unit(count, :one)
  end

  # Helper function for returning a tuple of {value, unit}
  defp scale_with_unit(count, unit) do
    {scale(count, unit), unit}
  end

  @doc """
  Scales a value representing a count in ones into a specified unit

  ## Examples

      iex> Benchee.Conversion.Count.scale(12345, :one)
      12345

      iex> Benchee.Conversion.Count.scale(12345, :thousand)
      12.345

      iex> Benchee.Conversion.Count.scale(12345, :billion)
      1.2345e-5

      iex> Benchee.Conversion.Count.scale(12345, :million)
      0.012345

  """
  def scale(count, :billion) do
    count / @one_billion
  end
  def scale(count, :million) do
    count / @one_million
  end
  def scale(count, :thousand) do
    count / @one_thousand
  end
  def scale(count, :one) do
    count
  end

  @doc """
  Finds the best unit for a list of counts. By default, chooses the most common
  unit. In case of tie, chooses the largest of the most common units.

  Pass `[strategy: :smallest]` to always return the smallest unit in the list.
  Pass `[strategy: :largest]` to always return the largest unit in the list.

  ## Examples

      iex> Benchee.Conversion.Count.best([23, 23_000, 34_000, 2_340_000])
      :thousand

      iex> Benchee.Conversion.Count.best([23, 23_000, 34_000, 2_340_000, 3_450_000])
      :million

      iex> Benchee.Conversion.Count.best([23, 23_000, 34_000, 2_340_000], strategy: :smallest)
      :one

      iex> Benchee.Conversion.Count.best([23, 23_000, 34_000, 2_340_000], strategy: :largest)
      :million

  """
  def best(list, opts \\ [strategy: :best])
  def best(list, opts) do
    Scale.best_unit(list, __MODULE__, opts)
  end

  @doc """
  The raw count, unscaled.

  ## Examples

      iex> Benchee.Conversion.Count.base_unit
      :one

  """
  def base_unit, do: :one

  @doc """
  Formats a number as a string, with a unit label. To specify the unit, pass
  a tuple of `{value, unit_atom}` like `{1_234, :million}`

  ## Examples

      iex> Benchee.Conversion.Count.format(45_678.9)
      "45.68 K"

      iex> Benchee.Conversion.Count.format(45.6789)
      "45.68"

      iex> Benchee.Conversion.Count.format({45.6789, :thousand})
      "45.68 K"
  """
  def format(count) do
    Format.format(count, __MODULE__)
  end

  @doc """
  A string that appears between a value and unit label when formatted. For
  this module, a space
  """
  def separator, do: " "
end
