defmodule Benchee.Config do
  @moduledoc """
  Functions to handle the configuration of Benchee, exposes `init` function.
  """

  alias Benchee.Time

  @doc """
  Returns the initial benchmark configuration for Benhee, composed of defauls
  and an optional custom configuration.
  Configuration times are given in seconds, but are converted to microseconds.

  Possible options:

    * parallel - the amount of parallel processes that are spawned to run the benchmark in
    * time     - total run time in seconds of a single benchmark (determines how
                 often it is executed). Defaults to 5.
    * warmup   - the time in seconds for which the benchmarking function should be run
                 without gathering results. Defaults to 2.

  ## Examples

      iex> Benchee.init
      %{config: %{parallel: 1, time: 5_000_000, warmup: 2_000_000}, jobs: []}

      iex> Benchee.init %{time: 1, warmup: 0.2}
      %{config: %{parallel: 1, time: 1_000_000, warmup: 200_000.0}, jobs: []}

  """
  @default_config %{parallel: 1, time: 5, warmup: 2}
  @time_keys [:time, :warmup]
  def init(config \\ %{}) do
    config = convert_time_to_micro_s(Map.merge(@default_config, config))
    :ok = :timer.start
    %{config: config, jobs: []}
  end

  defp convert_time_to_micro_s(config) do
    Enum.reduce @time_keys, config, fn(key, new_config) ->
      {_, new_config} = Map.get_and_update! new_config, key, fn(seconds) ->
        {seconds, Time.seconds_to_microseconds(seconds)}
      end
      new_config
    end
  end
end
