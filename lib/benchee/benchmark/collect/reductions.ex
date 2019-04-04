defmodule Benchee.Benchmark.Collect.Reductions do
  @moduledoc false

  @behaviour Benchee.Benchmark.Collect

  def collect(fun) do
    parent = self()

    # The reduction offset here is important - this is the number of reductions
    # that are needed for the other functions in our runner process that don't
    # have anything to do with the function that's being benchmarked.
    #
    # It includes the one reduction for the function that we have wrapping the
    # actual function being benchmarked, and then the rest are for the
    # collection of the initial reduction count and the ending reduction count.
    # These numbers vary based on the Erlang/OTP version, but not based on the
    # Elixir version (based on my experiements of everything from OTP 19 - 22
    # and Elixir 1.6 - 1.8).
    reduction_offset =
      case Benchee.System.erlang() do
        "22" <> _ -> 8
        "21" <> _ -> 8
        "20" <> _ -> 7
        "19" <> _ -> 7
      end

    spawn_link(fn ->
      start = get_reductions()
      output = fun.()
      send(parent, {get_reductions() - start - reduction_offset, output})
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
