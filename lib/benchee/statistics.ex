defmodule Benchee.Statistics do
  alias Benchee.Time

  @doc """
  Calculates statistical data based on a series of run times in microseconds.

  iex> Benchee.Statistics.statistics([200, 400, 400, 400, 500, 500, 700, 900])
  %{average: 500.0, std_dev: 200.0, ips: 2000.0}
  """
  def statistics(run_times) do
    total_time            = Enum.sum(run_times)
    iterations            = Enum.count(run_times)
    average_time          = total_time / iterations
    iterations_per_second = iterations_per_second(iterations, total_time)
    standard_deviation    = standard_deviation(run_times, average_time, iterations)

    %{
      average: average_time,
      ips:     iterations_per_second,
      std_dev: standard_deviation
    }
  end

  defp iterations_per_second(iterations, time_microseconds) do
    iterations / (Time.microseconds_to_seconds(time_microseconds))
  end

  defp standard_deviation(samples, average, iterations) do
    total_variance = Enum.reduce samples, 0,  fn(sample, total) ->
      total + :math.pow((sample - average), 2)
    end
    variance = total_variance / iterations
    :math.sqrt variance
  end
end
