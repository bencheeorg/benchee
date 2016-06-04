defmodule Benchee.Config do
  @moduledoc """
  Functions to handle the configuration of Benchee, exposes `init` function.
  """

  alias Benchee.Time

  @doc """
  Returns the initial benchmark configuration for Benhee, composed of defauls
  and an optional custom confiuration.
  Configuration times are given in seconds, but are converted to microseconds.

  Possible options:

    * time - total run time of a single benchmark (determines how often it is
      executed)

  ## Examples

      iex> Benchee.Config.init
      %{config: %{time: 5_000_000}, jobs: []}

      iex> Benchee.Config.init %{time: 1}
      %{config: %{time: 1_000_000}, jobs: []}

  """
  @default_config %{time: 5}
  def init(config \\ %{}) do
    config = convert_time_to_micro_s(Map.merge(@default_config, config))
    %{config: config, jobs: []}
  end

  defp convert_time_to_micro_s(config) do
    {_, config} = Map.get_and_update! config, :time, fn(seconds) ->
      {seconds, Time.seconds_to_microseconds(seconds)}
    end
    config
  end
end
