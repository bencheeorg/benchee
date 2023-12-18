defmodule Benchee.Benchmark.BenchmarkConfig do
  @moduledoc """
  Benchmark Configuration, practically a sub set of `Benchee.Configuration`

  `Benchee.Configuration` holds too much data that we don't want to send into the benchmarking
  processes - inputs being potentially huge. Hence, we take the sub set the benchmarks need and
  put it in here. Since this is a benchmarking library, to no one's surprise these are a lot of
  them.
  See: https://github.com/bencheeorg/benchee/issues/412
  """

  alias Benchee.Benchmark.Hooks

  @keys [
    :warmup,
    :time,
    :memory_time,
    :reduction_time,
    :pre_check,
    :measure_function_call_overhead,
    :before_each,
    :after_each,
    :before_scenario,
    :after_scenario,
    :parallel,
    :print
  ]

  defstruct @keys

  @type t :: %__MODULE__{
          time: number,
          warmup: number,
          memory_time: number,
          reduction_time: number,
          pre_check: boolean,
          measure_function_call_overhead: boolean,
          print: map,
          before_each: Hooks.hook_function() | nil,
          after_each: Hooks.hook_function() | nil,
          before_scenario: Hooks.hook_function() | nil,
          after_scenario: Hooks.hook_function() | nil,
          measure_function_call_overhead: boolean,
          parallel: pos_integer()
        }

  alias Benchee.Configuration

  def from(config = %Configuration{}) do
    values = Map.take(config, @keys)
    struct!(__MODULE__, values)
  end
end
