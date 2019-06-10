defmodule Statistex do
  @moduledoc """
  Statistics related functionality that is meant to take the raw benchmark data
  and then compute statistics like the average and the standard deviation etc.

  See `statistics/1` for a breakdown of the included statistics.
  """

  alias Statistex.{Mode, Percentile}
  require Integer

  defstruct [
    :average,
    :std_dev,
    :std_dev_ratio,
    :median,
    :percentiles,
    :mode,
    :minimum,
    :maximum,
    :relative_more,
    :relative_less,
    :absolute_difference,
    sample_size: 0
  ]

  @typedoc """
  All the statistics `statistics/1` computes from the samples.

  Overview of all the statistics benchee currently provides:

    * average       - average run time of the job in μs (the lower the better)
    * ips           - iterations per second, how often can the given function be
      executed within one second (the higher the better)
    * std_dev       - standard deviation, a measurement how much results vary
      (the higher the more the results vary)
    * std_dev_ratio - standard deviation expressed as how much it is relative to
      the average
    * std_dev_ips   - the absolute standard deviation of iterations per second
      (= ips * std_dev_ratio)
    * median        - when all measured times are sorted, this is the middle
      value (or average of the two middle values when the number of times is
      even). More stable than the average and somewhat more likely to be a
      typical value you see.
    * percentiles   - a map of percentile ranks. These are the values below
      which x% of the run times lie. For example, 99% of run times are shorter
      than the 99th percentile (99th %) rank.
      is a value for which 99% of the run times are shorter.
    * mode          - the run time(s) that occur the most. Often one value, but
      can be multiple values if they occur the same amount of times. If no value
      occurs at least twice, this value will be nil.
    * minimum       - the smallest sample measured for the scenario
    * maximum       - the biggest sample measured for the scenario
    * relative_more - relative to the reference (usually the fastest scenario) how much more
      was the average of this scenario. E.g. for reference at 100, this scenario 200 then it
      is 2.0.
    * relative_less - relative to the reference (usually the fastest scenario) how much less
      was the average of this scenario. E.g. for reference at 100, this scenario 200 then it
      is 0.5.
    * absolute_difference - relative to the reference (usually the fastest scenario) what is
      the difference of the averages of the scenarios. e.g. for reference at 100, this
      scenario 200 then it is 100.
    * sample_size   - the number of run time measurements taken
  """
  @type t :: %__MODULE__{
          average: float,
          std_dev: float,
          std_dev_ratio: float,
          median: number,
          percentiles: %{number => float},
          mode: Statistex.Mode.mode(),
          minimum: number,
          maximum: number,
          relative_more: float | nil | :infinity,
          relative_less: float | nil | :infinity,
          absolute_difference: float | nil,
          sample_size: non_neg_integer
        }

  @typedoc """
  The samples a `Benchee.Collect` collected to compute statistics from.
  """
  @type samples :: [number]

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
    total = Enum.sum(samples)
    num_iterations = length(samples)
    average = total / num_iterations
    deviation = standard_deviation(samples, average, num_iterations)
    standard_dev_ratio = if average == 0, do: 0, else: deviation / average

    percentiles = Keyword.get(configuration, :percentiles, [])
    percentiles = Enum.uniq([50 | percentiles])

    percentiles = Percentile.percentiles(samples, percentiles)
    median = Map.fetch!(percentiles, 50)
    mode = Mode.mode(samples)
    minimum = Enum.min(samples)
    maximum = Enum.max(samples)

    %__MODULE__{
      average: average,
      std_dev: deviation,
      std_dev_ratio: standard_dev_ratio,
      median: median,
      percentiles: percentiles,
      mode: mode,
      minimum: minimum,
      maximum: maximum,
      sample_size: num_iterations
    }
  end

  defdelegate percentiles(samples, percentiles), to: Percentile

  defp standard_deviation(_samples, _average, 1), do: 0

  defp standard_deviation(samples, average, sample_size) do
    total_variance =
      Enum.reduce(samples, 0, fn sample, total ->
        total + :math.pow(sample - average, 2)
      end)

    variance = total_variance / (sample_size - 1)
    :math.sqrt(variance)
  end
end
