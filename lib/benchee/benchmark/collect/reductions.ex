defmodule Benchee.Benchmark.Collect.Reductions do
  @moduledoc false

  @behaviour Benchee.Benchmark.Collect

  def collect(fun) do
    parent = self()

    spawn_link(fn ->
      start = get_reductions()
      output = fun.()
      send(parent, {get_reductions() - start, output})
    end)

    receive do
      result -> result
    end
  end

  defp get_reductions do
    {:reductions, reductions} = Process.info(self(), :reductions)
    reductions
  end
end
