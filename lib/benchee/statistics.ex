defmodule Benchee.Statistics do
  @moduledoc """
  Statistics related functionality that is meant to take the raw benchmark run
  times and then compute statistics like the average and the standard devaition.
  """

  alias Benchee.{Time, Statistics}
  require Integer

  @doc """
  Takes a job suite with job run times, returns a map representing the
  statistics of the job suite as follows:

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
      typical you see.

  ## Parameters

  * `suite` - the job suite represented as a map after running the measurements,
    required to have the run_times available under the `run_times` key

  ## Examples

      iex> run_times = [200, 400, 400, 400, 500, 500, 700, 900]
      iex> suite = %{run_times: %{"My Job" => run_times}}
      iex> Benchee.Statistics.statistics(suite)
      %{
        statistics: %{
          "My Job" => %{
            average:       500.0,
            ips:           2000.0,
            std_dev:       200.0,
            std_dev_ratio: 0.4,
            std_dev_ips:   800.0,
            median:        450.0
          }
        },
        run_times: %{"My Job" => [200, 400, 400, 400, 500, 500, 700, 900]}
      }

  """
  def statistics(suite = %{run_times: run_times}) do
    statistics =
      run_times
      |> Enum.map(fn({name, job_run_times}) ->
          {name, Statistics.job_statistics(job_run_times)}
        end)
      |> Map.new

    Map.put suite, :statistics, statistics
  end

  @doc """
  Calculates statistical data based on a series of run times for a job
  in microseconds.

  ## Examples

      iex> run_times = [200, 400, 400, 400, 500, 500, 700, 900]
      iex> Benchee.Statistics.job_statistics(run_times)
      %{average:       500.0,
        ips:           2000.0,
        std_dev:       200.0,
        std_dev_ratio: 0.4,
        std_dev_ips:   800.0,
        median:        450.0}

  """
  def job_statistics(run_times) do
    total_time          = Enum.sum(run_times)
    iterations          = Enum.count(run_times)
    average             = total_time / iterations
    ips                 = iterations_per_second(average)
    deviation           = standard_deviation(run_times, average, iterations)
    standard_dev_ratio  = deviation / average
    standard_dev_ips    = ips * standard_dev_ratio
    median              = compute_median(run_times, iterations)

    %{
      average:       average,
      ips:           ips,
      std_dev:       deviation,
      std_dev_ratio: standard_dev_ratio,
      std_dev_ips:   standard_dev_ips,
      median:        median,
    }
  end

  @doc """
  Sorts the given jobs fastest to slowest by average.

  ## Examples

      iex> jobs = %{"Second" => %{average: 200.0}, "Third"  => %{average: 400.0}, "First"  => %{average: 100.0}}
      iex> Benchee.Statistics.sort(jobs)
      [{"First",  %{average: 100.0}},
       {"Second", %{average: 200.0}},
       {"Third",  %{average: 400.0}}]
  """
  def sort(jobs) do
    Enum.sort_by jobs, fn({_, %{average: average}}) -> average end
  end

  defp iterations_per_second(average_microseconds) do
    Time.seconds_to_microseconds(1) / average_microseconds
  end

  defp standard_deviation(samples, average, iterations) do
    total_variance = Enum.reduce samples, 0,  fn(sample, total) ->
      total + :math.pow((sample - average), 2)
    end
    variance = total_variance / iterations
    :math.sqrt variance
  end

  defp compute_median(run_times, iterations) do
    # this is rather inefficient, as O(log(n) * n + n) - there are
    # O(n) algorithms to do compute this should it get to be a problem.
    sorted = Enum.sort(run_times)
    middle = div(iterations, 2)

    if Integer.is_odd(iterations) do
      sorted |> Enum.at(middle) |> to_float
    else
      (Enum.at(sorted, middle) + Enum.at(sorted, middle - 1)) / 2
    end
  end

  defp to_float(maybe_integer) do
    :erlang.float maybe_integer
  end
end
