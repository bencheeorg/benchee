defmodule Benchee.Benchmark.Collect.Profile do
  @moduledoc """
  Collect/generate a profile.

  The most unusual collector, as it doesn't return measured values really.

  It still goes around and gathers data about a passed in function and so made sense
  to put it into similar confines.
  """
  @default_profiler Benchee.Profile.default_profiler()
  def collect(function, opts \\ [profiler_module: @default_profiler, profiler_opts: []]) do
    {:ok, profiler_module} = Access.fetch(opts, :profiler_module)
    profiler_opts = Access.get(opts, :profiler_opts, [])

    # note, I already put this here but it doesn't work yet
    # needs the release of this PR: https://github.com/elixir-lang/elixir/pull/11657
    return_value = profiler_module.profile(function, profiler_opts)

    {nil, return_value}
  end
end
