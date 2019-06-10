defmodule Statistex do
  @moduledoc """
  Statistics related functionality that is meant to take the raw benchmark data
  and then compute statistics like the average and the standard deviation etc.

  See `statistics/1` for a breakdown of the included statistics.
  """

  alias Statistex.{Mode, Percentile}
  require Integer

  defstruct [
    :total,
    :average,
    :standard_deviation,
    :standard_deviation_ratio,
    :median,
    :percentiles,
    :mode,
    :minimum,
    :maximum,
    sample_size: 0
  ]

  @typedoc """
  All the statistics `statistics/1` computes from the samples.

  Overview of all the statistics benchee currently provides:

    * total         - the sum of all the samples
    * average       - well... the average
    * std_dev       - standard deviation, a measurement how much samples vary
      (the higher the more the samples vary)
    * std_dev_ratio - standard deviation expressed as how much it is relative to
      the average
    * median        - when all samples are sorted, this is the middle
      value (or average of the two middle values when the number of times is
      even). More stable than the average.
    * percentiles   - a map of percentile ranks. These are the values below
      which x% of the samples lie. For example, 99% of samples are less
      than the 99th percentile (99th %) rank.
      is a value for which 99% of the run times are shorter.
    * mode          - the sample(s) that occur the most. Often one value, but
      can be multiple values if they occur the same amount of times. If no value
      occurs at least twice, this value will be nil.
    * minimum       - the smallest sample
    * maximum       - the biggest sample
    * sample_size   - the number of run time measurements taken
  """
  @type t :: %__MODULE__{
          total: number,
          average: float,
          standard_deviation: float,
          standard_deviation_ratio: float,
          median: number,
          percentiles: %{number => float},
          mode: Statistex.Mode.mode(),
          minimum: number,
          maximum: number,
          sample_size: non_neg_integer
        }

  @typedoc """
  The samples a `Benchee.Collect` collected to compute statistics from.
  """
  @type samples :: [sample]
  @type sample :: number

  @type configuration :: keyword
  @doc """
  WIP
  """
  @spec statistics(samples, configuration) :: t()
  def statistics(samples, configuration \\ [])

  def statistics([], _) do
    %__MODULE__{sample_size: 0}
  end

  def statistics(samples, configuration) do
    total = total(samples)
    sample_size = length(samples)
    average = average(samples, total: total, sample_size: sample_size)
    standard_deviation = standard_deviation(samples, average: average, sample_size: sample_size)

    standard_deviation_ratio =
      standard_deviation_ratio(samples, average: average, standard_deviation: standard_deviation)

    percentiles = calculate_percentiles(samples, configuration)
    median = median(samples, percentiles: percentiles)

    %__MODULE__{
      total: total,
      average: average,
      standard_deviation: standard_deviation,
      standard_deviation_ratio: standard_deviation_ratio,
      median: median,
      percentiles: percentiles,
      mode: mode(samples),
      minimum: minimum(samples),
      maximum: maximum(samples),
      sample_size: sample_size
    }
  end

  @spec total(samples) :: number
  def total(samples), do: Enum.sum(samples)

  @spec sample_size(samples) :: non_neg_integer
  def sample_size(samples), do: length(samples)

  @spec average(samples, keyword) :: float
  def average(samples, options \\ []) do
    total = Keyword.get_lazy(options, :total, fn -> total(samples) end)
    sample_size = Keyword.get_lazy(options, :sample_size, fn -> sample_size(samples) end)

    total / sample_size
  end

  @spec standard_deviation(samples, keyword) :: float
  def standard_deviation(samples, options \\ []) do
    sample_size = Keyword.get_lazy(options, :sample_size, fn -> sample_size(samples) end)

    average =
      Keyword.get_lazy(options, :average, fn -> average(samples, sample_size: sample_size) end)

    do_standard_deviation(samples, average, sample_size)
  end

  defp do_standard_deviation(_samples, _average, 1), do: 0.0

  defp do_standard_deviation(samples, average, sample_size) do
    total_variance =
      Enum.reduce(samples, 0, fn sample, total ->
        total + :math.pow(sample - average, 2)
      end)

    variance = total_variance / (sample_size - 1)
    :math.sqrt(variance)
  end

  @spec standard_deviation_ratio(samples, keyword) :: float
  def standard_deviation_ratio(samples, options) do
    average = Keyword.get_lazy(options, :average, fn -> average(samples) end)

    std_dev =
      Keyword.get_lazy(options, :standard_deviation, fn ->
        standard_deviation(samples, average: average)
      end)

    if average == 0 do
      0.0
    else
      std_dev / average
    end
  end

  @median_percentile 50
  defp calculate_percentiles(samples, configuration) do
    percentiles_configuration = Keyword.get(configuration, :percentiles, [])

    # 50 is manually added so that it can be used directly by median
    percentiles_configuration = Enum.uniq([@median_percentile | percentiles_configuration])
    percentiles(samples, percentiles_configuration)
  end

  defdelegate percentiles(samples, percentiles), to: Percentile
  defdelegate mode(samples), to: Mode

  @spec median(samples, keyword) :: number
  def median(samples, options \\ []) do
    percentiles =
      Keyword.get_lazy(options, :percentiles, fn -> percentiles(samples, @median_percentile) end)

    Map.get_lazy(percentiles, @median_percentile, fn ->
      samples |> percentiles(@median_percentile) |> Map.fetch!(@median_percentile)
    end)
  end

  @spec maximum(samples) :: sample
  def maximum(samples), do: Enum.max(samples)
  @spec minimum(samples) :: sample
  def minimum(samples), do: Enum.min(samples)
end
