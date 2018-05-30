defmodule Benchee.Statistics.Percentile do
  @moduledoc false

  @type percentile :: float()
  @type percentiles :: %{optional(number()) => percentile()}

  @doc """
  Calculates the value at the `percentile_rank`-th percentile. Think of this as the
  value below which `percentile_rank` percent of the samples lie. For example,
  if `Benchee.Statistics.Percentile.percentile(samples, 99)` == 123.45,
  99% of samples are less than 123.45.

  Passing a number for `percentile_rank` calculates a single percentile.
  Passing a list of numbers calculates multiple percentiles, and returns them
  as a map like %{90 => 45.6, 99 => 78.9}, where the keys are the percentile
  numbers, and the values are the percentile values.

  ## Examples

  iex> Benchee.Statistics.Percentile.percentiles([5, 3, 4, 5, 1, 3, 1, 3], 12.5)
  %{12.5 => 1.0}

  iex> Benchee.Statistics.Percentile.percentiles([5, 3, 4, 5, 1, 3, 1, 3], [50])
  %{50 => 3.0}

  iex> Benchee.Statistics.Percentile.percentiles([5, 3, 4, 5, 1, 3, 1, 3], [75])
  %{75 => 4.75}

  iex> Benchee.Statistics.Percentile.percentiles([5, 3, 4, 5, 1, 3, 1, 3], 99)
  %{99 => 5.0}

  iex> Benchee.Statistics.Percentile.percentiles([5, 3, 4, 5, 1, 3, 1, 3], [50, 75, 99])
  %{50 => 3.0, 75 => 4.75, 99 => 5.0}

  iex> Benchee.Statistics.Percentile.percentiles([5, 3, 4, 5, 1, 3, 1, 3], 100)
  ** (ArgumentError) percentile must be between 0 and 100, got: 100

  iex> Benchee.Statistics.Percentile.percentiles([5, 3, 4, 5, 1, 3, 1, 3], 0)
  ** (ArgumentError) percentile must be between 0 and 100, got: 0
  """
  @spec percentiles([number()], number | [number()]) :: percentiles
  def percentiles(samples, percentile_ranks) do
    number_of_samples = length(samples)
    sorted_samples = Enum.sort(samples)

    percentile_ranks
    |> List.wrap()
    |> Enum.reduce(%{}, fn percentile_rank, acc ->
      perc = percentile(sorted_samples, number_of_samples, percentile_rank)
      Map.put(acc, percentile_rank, perc)
    end)
  end

  defp percentile(_, _, percentile_rank) when percentile_rank >= 100 or percentile_rank <= 0 do
    raise ArgumentError, "percentile must be between 0 and 100, got: #{inspect(percentile_rank)}"
  end

  defp percentile(sorted_samples, number_of_samples, percentile_rank) do
    rank = percentile_rank / 100 * max(0, number_of_samples + 1)
    percentile_value(sorted_samples, rank)
  end

  defp percentile_value(sorted_samples, rank) do
    index = max(0, trunc(rank) - 1)
    {pre_index, post_index} = Enum.split(sorted_samples, index)
    calculate_percentile_value(rank, pre_index, post_index)
  end

  # The common case: interpolate between the two values after the split
  defp calculate_percentile_value(rank, _, [lower_bound, upper_bound | _]) do
    lower_bound + interpolation_value(lower_bound, upper_bound, rank)
  end

  # Nothing to interpolate toward: use the first value after the split
  defp calculate_percentile_value(_, _, [lower_bound]) do
    to_float(lower_bound)
  end

  # Nothing at all: error
  defp calculate_percentile_value(_, [], []) do
    raise ArgumentError, "can't calculate percentile value on an empty list"
  end

  # Nothing beyond the split: use the last value before the split
  defp calculate_percentile_value(_, previous_values, []) do
    previous_values
    |> Enum.reverse()
    |> hd
    |> to_float
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
    :erlang.float(maybe_integer)
  end
end
