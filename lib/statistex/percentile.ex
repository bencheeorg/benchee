defmodule Statistex.Percentile do
  @moduledoc false

  @spec percentiles(Statistex.samples(), number | [number, ...]) ::
          Statistex.percentiles()
  def percentiles([], _) do
    raise(
      ArgumentError,
      "Passed an empty list ([]) to calculate statistics from, please pass a list containing at least on number."
    )
  end

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
    percent = percentile_rank / 100
    rank = percent * (number_of_samples + 1)
    percentile_value(sorted_samples, rank)
  end

  # According to https://www.itl.nist.gov/div898/handbook/prc/section2/prc262.htm
  # the full integer of rank being 0 is an edge case and we simple choose the first
  # element. See clause 2, our rank is k there.
  defp percentile_value(sorted_samples, rank) when rank < 1 do
    [first | _] = sorted_samples
    first
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

  # Interpolation implemented according to: https://www.itl.nist.gov/div898/handbook/prc/section2/prc262.htm
  #
  # "Type 6" interpolation strategy. There are many ways to interpolate a value
  # when the rank is not an integer (in other words, we don't exactly land on a
  # particular sample). Of the 9 main strategies, (types 1-9), types 6, 7, and 8
  # are generally acceptable and give similar results.
  #
  # For more information on interpolation strategies, see:
  # - https://stat.ethz.ch/R-manual/R-devel/library/stats/html/quantile.html
  # - http://www.itl.nist.gov/div898/handbook/prc/section2/prc262.htm
  defp interpolation_value(lower_bound, upper_bound, rank) do
    # in our source rank is k, and interpolation_weitgh is d
    interpolation_weight = rank - trunc(rank)
    interpolation_weight * (upper_bound - lower_bound)
  end

  defp to_float(maybe_integer) do
    :erlang.float(maybe_integer)
  end
end
