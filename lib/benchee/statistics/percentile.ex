defmodule Benchee.Statistics.Percentile do
  @moduledoc false

  alias Benchee.Statistics

  @doc """
  Calculates the value at the `percentile_number`-th percentile. Think of this as the
  value below which `percentile_number` percent of the samples lie. For example,
  if `Benchee.Statistics.Percentile.percentile(samples, 99)` == 123.45,
  99% of samples are less than 123.45.

  ## Examples

  iex> Benchee.Statistics.Percentile.percentile([5, 3, 4, 5, 1, 3, 1, 3], 8, 100)
  5.0

  iex> Benchee.Statistics.Percentile.percentile([5, 3, 4, 5, 1, 3, 1, 3], 8, 150)
  5.0

  iex> Benchee.Statistics.Percentile.percentile([5, 3, 4, 5, 1, 3, 1, 3], 8, 0)
  1.0

  iex> Benchee.Statistics.Percentile.percentile([5, 3, 4, 5, 1, 3, 1, 3], 8, -1)
  1.0

  iex> Benchee.Statistics.Percentile.percentile([5, 3, 4, 5, 1, 3, 1, 3], 50)
  3.0

  iex> Benchee.Statistics.Percentile.percentile([5, 3, 4, 5, 1, 3, 1, 3], 75)
  4.75
  """
  @spec percentile(list(number()), integer()) :: float()
  def percentile(samples, percentile_number) do
    percentile(samples, length(samples), percentile_number)
  end

  @spec percentile(list(number()), integer(), integer()) :: float()
  def percentile(samples, number_of_samples, percentile_number) when percentile_number > 100 do
    percentile(samples, number_of_samples, 100)
  end

  def percentile(samples, number_of_samples, percentile_number) when percentile_number < 0 do
    percentile(samples, number_of_samples, 0)
  end

  def percentile(samples, number_of_samples, percentile_number) do
    sorted = Enum.sort(samples)
    rank = (percentile_number / 100) * max(0, number_of_samples + 1)
    percentile_value(sorted, rank)
  end

  defp percentile_value(sorted, rank) when trunc(rank) == 0 do
    sorted
    |> hd
    |> to_float
  end

  defp percentile_value(sorted, rank) when trunc(rank) >= length(sorted) do
    sorted
    |> Enum.reverse
    |> hd
    |> to_float
  end

  defp percentile_value(sorted, rank) do
    index = trunc(rank)
    [lower_bound, upper_bound | _] = Enum.drop(sorted, index - 1)
    interpolation_value = interpolation_value(lower_bound, upper_bound, rank)
    lower_bound + interpolation_value
  end

  # "Type 6" interpolation strategy. There are many ways to interpolate a value
  # when the rank is not an integer (in other words, we don't exactly land on a
  # particular sample). Of the 9 main strategies, (types 1-9), types 6, 7, and 8
  # are generally acceptable and give similar results.
  #
  # See also:
  # - [documentation from R language](https://stat.ethz.ch/R-manual/R-devel/library/stats/html/quantile.html)
  # - [NIST handbook](http://www.itl.nist.gov/div898/handbook/prc/section2/prc262.htm)
  defp interpolation_value(lower_bound, upper_bound, rank) do
    interpolation_weight = rank - trunc(rank)
    interpolation_weight * (upper_bound - lower_bound)
  end

  defp to_float(maybe_integer) do
    :erlang.float maybe_integer
  end
end
