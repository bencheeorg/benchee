defmodule Statistex do
  @moduledoc """
  Calculate all the statistics for given samples.

  Works all at once with `statistics/1` or has a lot of functions that can be triggered individually.

  To avoid wasting computation, function can be given values they depend on as optional keyword arguments so that these values can be used instead of recalculating them. For an example see `average/2`.

  Most statistics don't really make sense when there are no samples, for that reason all functions except for `sample_size/1` raise `ArgumentError` when handed an empty list.
  It is suggested that if it's possible for your program to throw an empty list at Statistex to handle that before handing it to Staistex to take care of the "no reasonable statistics" path entirely separately.
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

  For a description of what a given value means please check out the function here by the same name, it will have an explanation.
  """
  @type t :: %__MODULE__{
          total: number,
          average: float,
          standard_deviation: float,
          standard_deviation_ratio: float,
          median: number,
          percentiles: percentiles,
          mode: mode,
          minimum: number,
          maximum: number,
          sample_size: non_neg_integer
        }

  @typedoc """
  The samples to compute statistics from.

  Importantly this list is not empty/includes at least one sample otherwise an `ArgumentError` will be raised.
  """
  @type samples :: [sample, ...]

  @typedoc """
  A single sample/
  """
  @type sample :: number

  @typedoc """
  The optional configuration handed to a lot of functions.

  Keys used are function dependent and are documented there.
  """
  @type configuration :: keyword

  @typedoc """
  Careful with the mode, might be multiple values, one value or nothing.😱 See `mode/1`.
  """
  @type mode :: [sample()] | sample() | nil

  @typedoc """
  The percentiles map returned by `percentiles/2`.
  """
  @type percentiles :: %{number() => float}

  @empty_list_error_message "Passed an empty list ([]) to calculate statistics from, please pass a list containing at least on number."

  @doc """
  Calculate all statistics Statistex offers for a given list of numbers.

  The statistics themselves are described in the individual samples that can be used to calculate individual values.

  `Argumenterror` is raised if the given list is empty.

  ## Options
  In a `percentiles` options arguments for the calculation of percentiles (see `percentiles/2`) can be given. The 50th percentile is always calculated as it is the median.

  ## Examples

      iex> Statistex.statistics([200, 400, 400, 400, 500, 500, 500, 700, 900])
      %Statistex{
        average:                  500.0,
        standard_deviation:       200.0,
        standard_deviation_ratio: 0.4,
        median:                   500.0,
        percentiles:              %{50 => 500.0},
        mode:                     [500, 400],
        minimum:                  200,
        maximum:                  900,
        sample_size:              9,
        total:                    4500
      }

      iex> Statistex.statistics([])
      ** (ArgumentError) Passed an empty list ([]) to calculate statistics from, please pass a list containing at least on number.

      iex> Statistex.statistics([0, 0, 0, 0])
      %Statistex{
        average:                  0.0,
        standard_deviation:       0.0,
        standard_deviation_ratio: 0.0,
        median:                   0.0,
        percentiles:              %{50 => 0.0},
        mode:                     0,
        minimum:                  0,
        maximum:                  0,
        sample_size:              4,
        total:                    0
      }

  """
  @spec statistics(samples, configuration) :: t()
  def statistics(samples, configuration \\ [])

  def statistics([], _) do
    raise(ArgumentError, @empty_list_error_message)
  end

  def statistics(samples, configuration) do
    total = total(samples)
    sample_size = length(samples)
    average = average(samples, total: total, sample_size: sample_size)
    standard_deviation = standard_deviation(samples, average: average, sample_size: sample_size)

    standard_deviation_ratio =
      standard_deviation_ratio(
        samples,
        average: average,
        standard_deviation: standard_deviation
      )

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

  @doc """
  The total of all samples added together.

  `Argumenterror` is raised if the given list is empty.

  ## Examples

      iex> Statistex.total([1, 2, 3, 4, 5])
      15

      iex> Statistex.total([10, 10.5, 5])
      25.5

      iex> Statistex.total([-10, 5, 3, 2])
      0

      iex> Statistex.total([])
      ** (ArgumentError) Passed an empty list ([]) to calculate statistics from, please pass a list containing at least on number.
  """
  @spec total(samples) :: number
  def total([]), do: raise(ArgumentError, @empty_list_error_message)
  def total(samples), do: Enum.sum(samples)

  @doc """
  Number of samples in the given list.

  Nothing to fancy here, this just calls `length(list)` and is only provided for completeness sake.

  ## Examples

      iex> Statistex.sample_size([])
      0

      iex> Statistex.sample_size([1, 1, 1, 1, 1])
      5
  """
  @spec sample_size([sample]) :: non_neg_integer
  def sample_size(samples), do: length(samples)

  @doc """
  Calculate the average.

  It's.. well the average.
  When the given samples are empty there is no average.

  `Argumenterror` is raised if the given list is empty.

  ## Options
  If you already have these values, you can provide both `:total` and `:sample_size`. Should you provide both the provided samples are wholly ignored.

  ## Examples

      iex> Statistex.average([5])
      5.0

      iex> Statistex.average([600, 470, 170, 430, 300])
      394.0

      iex> Statistex.average([-1, 1])
      0.0

      iex> Statistex.average([2, 3, 4], sample_size: 3)
      3.0

      iex> Statistex.average([20, 20, 20, 20, 20], total: 100, sample_size: 5)
      20.0

      iex> Statistex.average(:ignored, total: 100, sample_size: 5)
      20.0

      iex> Statistex.average([])
      ** (ArgumentError) Passed an empty list ([]) to calculate statistics from, please pass a list containing at least on number.
  """
  @spec average(samples, keyword) :: float
  def average(samples, options \\ [])
  def average([], _), do: raise(ArgumentError, @empty_list_error_message)

  def average(samples, options) do
    total = Keyword.get_lazy(options, :total, fn -> total(samples) end)
    sample_size = Keyword.get_lazy(options, :sample_size, fn -> sample_size(samples) end)

    if sample_size > 0 do
      total / sample_size
    else
      raise(ArgumentError, @empty_list_error_message)
    end
  end

  @doc """
  Calculate the standard deviation.

  A measurement how much samples vary (the higher the more the samples vary).

  ## Options
  If already calculated, the `:average` and `:sample_size` options can be provided to avoid recalulating those values.

  `Argumenterror` is raised if the given list is empty.

  ## Examples

      iex> Statistex.standard_deviation([4, 9, 11, 12, 17, 5, 8, 12, 12])
      4.0

      iex> Statistex.standard_deviation([4, 9, 11, 12, 17, 5, 8, 12, 12], sample_size: 9, average: 10.0)
      4.0

      iex> Statistex.standard_deviation([42])
      0.0

      iex> Statistex.standard_deviation([1, 1, 1, 1, 1, 1, 1])
      0.0

      iex> Statistex.standard_deviation([])
      ** (ArgumentError) Passed an empty list ([]) to calculate statistics from, please pass a list containing at least on number.
  """
  @spec standard_deviation(samples, keyword) :: float
  def standard_deviation(samples, options \\ [])
  def standard_deviation([], _), do: raise(ArgumentError, @empty_list_error_message)

  def standard_deviation(samples, options) do
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

  @doc """
    Calculate the standard deviation relative to the average.

    This helps put the absolute standard deviation value into perspective expressing it relative to the average. It's what percentage of the absolute value of the average the variance takes.

    ## Options
    If already calculated, the `:average` and `:standard_deviation` options can be provided to avoid recalulating those values.

    If both values are provided, the provided samples will be ignored.

    `Argumenterror` is raised if the given list is empty.

    ## Examples

        iex> Statistex.standard_deviation_ratio([4, 9, 11, 12, 17, 5, 8, 12, 12])
        0.4

        iex> Statistex.standard_deviation_ratio([-4, -9, -11, -12, -17, -5, -8, -12, -12])
        0.4

        iex> Statistex.standard_deviation_ratio([4, 9, 11, 12, 17, 5, 8, 12, 12], average: 10.0, standard_deviation: 4.0)
        0.4

        iex> Statistex.standard_deviation_ratio(:ignored, average: 10.0, standard_deviation: 4.0)
        0.4

        iex> Statistex.standard_deviation_ratio([])
        ** (ArgumentError) Passed an empty list ([]) to calculate statistics from, please pass a list containing at least on number.
  """
  @spec standard_deviation_ratio(samples, keyword) :: float
  def standard_deviation_ratio(samples, options \\ [])
  def standard_deviation_ratio([], _), do: raise(ArgumentError, @empty_list_error_message)

  def standard_deviation_ratio(samples, options) do
    average = Keyword.get_lazy(options, :average, fn -> average(samples) end)

    std_dev =
      Keyword.get_lazy(options, :standard_deviation, fn ->
        standard_deviation(samples, average: average)
      end)

    if average == 0 do
      0.0
    else
      abs(std_dev / average)
    end
  end

  @median_percentile 50
  defp calculate_percentiles(samples, configuration) do
    percentiles_configuration = Keyword.get(configuration, :percentiles, [])

    # median_percentile is manually added so that it can be used directly by median
    percentiles_configuration = Enum.uniq([@median_percentile | percentiles_configuration])
    percentiles(samples, percentiles_configuration)
  end

  @doc """
  Calculates the value at the `percentile_rank`-th percentile.

  Think of this as the
  value below which `percentile_rank` percent of the samples lie. For example,
  if `Statistex.percentile(samples, 99)` == 123.45,
  99% of samples are less than 123.45.

  Passing a number for `percentile_rank` calculates a single percentile.
  Passing a list of numbers calculates multiple percentiles, and returns them
  as a map like %{90 => 45.6, 99 => 78.9}, where the keys are the percentile
  numbers, and the values are the percentile values.

  Percentiles must be between 0 and 100 (excluding the boundaries).

  The method used for interpolation is [described here and recommended by NIST](https://www.itl.nist.gov/div898/handbook/prc/section2/prc262.htm).

  `Argumenterror` is raised if the given list is empty.

  ## Examples

      iex> Statistex.percentiles([5, 3, 4, 5, 1, 3, 1, 3], 12.5)
      %{12.5 => 1.0}

      iex> Statistex.percentiles([5, 3, 4, 5, 1, 3, 1, 3], [50])
      %{50 => 3.0}

      iex> Statistex.percentiles([5, 3, 4, 5, 1, 3, 1, 3], [75])
      %{75 => 4.75}

      iex> Statistex.percentiles([5, 3, 4, 5, 1, 3, 1, 3], 99)
      %{99 => 5.0}

      iex> Statistex.percentiles([5, 3, 4, 5, 1, 3, 1, 3], [50, 75, 99])
      %{50 => 3.0, 75 => 4.75, 99 => 5.0}

      iex> Statistex.percentiles([5, 3, 4, 5, 1, 3, 1, 3], 100)
      ** (ArgumentError) percentile must be between 0 and 100, got: 100

      iex> Statistex.percentiles([5, 3, 4, 5, 1, 3, 1, 3], 0)
      ** (ArgumentError) percentile must be between 0 and 100, got: 0

      iex> Statistex.percentiles([], [50])
      ** (ArgumentError) Passed an empty list ([]) to calculate statistics from, please pass a list containing at least on number.
  """
  @spec percentiles(samples, number | [number(), ...]) ::
          percentiles()
  defdelegate(percentiles(samples, percentiles), to: Percentile)

  @doc """
  Calculates the mode of the given samples.


  Mode is the sample(s) that occur the most. Often one value, but can be multiple values if they occur the same amount of times. If no value occurs at least twice, this value will be nil.

  `Argumenterror` is raised if the given list is empty.

  ## Examples

      iex> Statistex.mode([5, 3, 4, 5, 1, 3, 1, 3])
      3

      iex> Statistex.mode([1, 2, 3, 4, 5])
      nil

      iex> Statistex.mode([])
      ** (ArgumentError) Passed an empty list ([]) to calculate statistics from, please pass a list containing at least on number.

      iex> mode = Statistex.mode([5, 3, 4, 5, 1, 3, 1])
      iex> Enum.sort(mode)
      [1, 3, 5]
  """
  @spec mode(samples) :: mode
  defdelegate mode(samples), to: Mode

  @doc """
  Calculates the median of the given samples.

  The median can be thought of separating the higher half from the lower half of the samples.
  When all samples are sorted, this is the middle value (or average of the two middle values when the number of times is even).
  More stable than the average.

  `Argumenterror` is raised if the given list is empty.

  ## Examples

      iex> Statistex.median([1, 3, 4, 6, 7, 8, 9])
      6.0

      iex> Statistex.median([1, 2, 3, 4, 5, 6, 8, 9])
      4.5

      iex> Statistex.median([0])
      0.0

      iex> Statistex.median([])
      ** (ArgumentError) Passed an empty list ([]) to calculate statistics from, please pass a list containing at least on number.
  """
  @spec median(samples, keyword) :: number
  def median(samples, options \\ [])
  def median([], _), do: raise(ArgumentError, @empty_list_error_message)

  def median(samples, options) do
    percentiles =
      Keyword.get_lazy(options, :percentiles, fn -> percentiles(samples, @median_percentile) end)

    Map.get_lazy(percentiles, @median_percentile, fn ->
      samples |> percentiles(@median_percentile) |> Map.fetch!(@median_percentile)
    end)
  end

  @doc """
  The biggest sample.

  `Argumenterror` is raised if the given list is empty.

  ## Examples

      iex> Statistex.maximum([1, 100, 24])
      100

      iex> Statistex.maximum([])
      ** (ArgumentError) Passed an empty list ([]) to calculate statistics from, please pass a list containing at least on number.
  """
  @spec maximum(samples) :: sample
  def maximum([]), do: raise(ArgumentError, @empty_list_error_message)
  def maximum(samples), do: Enum.max(samples)

  @doc """
  The smallest sample.

  `Argumenterror` is raised if the given list is empty.

  ## Examples

      iex> Statistex.minimum([1, 100, 24])
      1

      iex> Statistex.minimum([])
      ** (ArgumentError) Passed an empty list ([]) to calculate statistics from, please pass a list containing at least on number.
  """
  @spec minimum(samples) :: sample
  def minimum([]), do: raise(ArgumentError, @empty_list_error_message)
  def minimum(samples), do: Enum.min(samples)
end
