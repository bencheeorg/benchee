defmodule Benchee.Statistics.Percentile do
  @moduledoc false

  @doc """
  Calculates the value at the `percentile_number`-th percentile. Think of this as the
  value below which `percentile_number` percent of the samples lie. For example,
  if `Benchee.Statistics.Percentile.percentile(samples, 99)` == 123.45,
  99% of samples are less than 123.45.

  ## Examples

  iex> Benchee.Statistics.Percentile.percentile([5, 3, 4, 5, 1, 3, 1, 3], 12.5)
  1.0

  iex> Benchee.Statistics.Percentile.percentile([5, 3, 4, 5, 1, 3, 1, 3], 50)
  3.0

  iex> Benchee.Statistics.Percentile.percentile([5, 3, 4, 5, 1, 3, 1, 3], 75)
  4.75

  iex> Benchee.Statistics.Percentile.percentile([5, 3, 4, 5, 1, 3, 1, 3], 99)
  5.0

  iex> Benchee.Statistics.Percentile.percentile([5, 3, 4, 5, 1, 3, 1, 3], 100)
  ** (ArgumentError) percentile must be between 0 and 100, got: 100

  iex> Benchee.Statistics.Percentile.percentile([5, 3, 4, 5, 1, 3, 1, 3], 0)
  ** (ArgumentError) percentile must be between 0 and 100, got: 0
  """
  @spec percentile(list(number()), integer()) :: float()
  def percentile(_, percentile_number) when percentile_number >= 100 or percentile_number <= 0 do
    raise ArgumentError, "percentile must be between 0 and 100, got: #{inspect(percentile_number)}"
  end

  def percentile(samples, percentile_number) do
    number_of_samples = length(samples)
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
  # For more information on interpolation strategies, see:
  # - https://stat.ethz.ch/R-manual/R-devel/library/stats/html/quantile.html
  # - http://www.itl.nist.gov/div898/handbook/prc/section2/prc262.htm
  defp interpolation_value(lower_bound, upper_bound, rank) do
    interpolation_weight = rank - trunc(rank)
    interpolation_weight * (upper_bound - lower_bound)
  end

  defp to_float(maybe_integer) do
    :erlang.float maybe_integer
  end
end
