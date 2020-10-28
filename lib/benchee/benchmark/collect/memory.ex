defmodule Benchee.Benchmark.Collect.Memory do
  @moduledoc false

  # Measure memory consumption of a function.
  #
  # This is somewhat tricky and hence some resources can be recommended reading alongside
  # this code:
  # * description of the approach: https://devonestes.herokuapp.com/using-erlang-trace-3
  # * devon describing the journey that this feature put us through (includes remarks
  #   on why certain parts are very important: https://www.youtube.com/watch?v=aqLujfzvUgM)
  # * erlang docs on the info data structure we use:
  #   http://erlang.org/doc/man/erlang.html#gc_minor_start
  #
  # Returns `{nil, return_value}` in case the memory measurement went bad.

  @behaviour Benchee.Benchmark.Collect

  defmacrop compatible_stacktrace do
    if Version.match?(Version.parse!(System.version()), "~> 1.7") do
      quote do
        __STACKTRACE__
      end
    else
      quote do
        System.stacktrace()
      end
    end
  end

  @spec collect((() -> any)) :: {nil | non_neg_integer, any}
  def collect(fun) do
    ref = make_ref()
    Process.flag(:trap_exit, true)
    start_runner(fun, ref)
    await_results(nil, ref)
  end

  defp await_results(return_value, ref) do
    receive do
      {^ref, memory_usage} ->
        return_memory({memory_usage, return_value})

      {^ref, :shutdown} ->
        nil

      # we need a really basic pattern here because sending anything other than
      # just what's returned from the function that we're benchmarking will
      # involve allocating a new term, which will skew the measurements.
      # We need to be very careful to always send the `ref` in every other
      # message to this process.
      new_result ->
        await_results(new_result, ref)
    end
  end

  defp start_runner(fun, ref) do
    parent = self()

    spawn_link(fn ->
      tracer = start_tracer(self())

      try do
        _ = measure_memory(fun, tracer, parent)
        word_size = :erlang.system_info(:wordsize)
        memory_used = get_collected_memory(tracer)
        send(parent, {ref, memory_used * word_size})
      catch
        kind, reason ->
          send(tracer, :done)
          send(parent, {ref, :shutdown})
          stacktrace = compatible_stacktrace()
          IO.puts(Exception.format(kind, reason, stacktrace))
          exit(:normal)
      after
        send(tracer, :done)
      end
    end)
  end

  defp return_memory({memory_usage, return_value}) when memory_usage < 0, do: {nil, return_value}
  defp return_memory(memory_usage_info), do: memory_usage_info

  defp measure_memory(fun, tracer, parent) do
    :erlang.garbage_collect()
    send(tracer, :begin_collection)

    receive do
      :ready_to_begin -> nil
    end

    return_value = fun.()
    send(parent, return_value)

    :erlang.garbage_collect()
    send(tracer, :end_collection)

    receive do
      :ready_to_end -> nil
    end

    # We need to reference these variables after we end our collection so
    # these don't get GC'd and counted towards the memory usage of the function
    # we're benchmarking.
    {parent, fun}
  end

  defp get_collected_memory(tracer) do
    ref = Process.monitor(tracer)
    send(tracer, {:get_collected_memory, self(), ref})

    receive do
      {:DOWN, ^ref, _, _, _} -> nil
      {^ref, collected} -> collected
    end
  end

  defp start_tracer(pid) do
    spawn(fn -> tracer_loop(pid, 0) end)
  end

  defp tracer_loop(pid, acc) do
    receive do
      :begin_collection ->
        :erlang.trace(pid, true, [:garbage_collection, tracer: self()])
        send(pid, :ready_to_begin)
        tracer_loop(pid, acc)

      :end_collection ->
        :erlang.trace(pid, false, [:garbage_collection])
        send(pid, :ready_to_end)
        tracer_loop(pid, acc)

      {:get_collected_memory, reply_to, ref} ->
        send(reply_to, {ref, acc})

      {:trace, ^pid, :gc_minor_start, info} ->
        listen_gc_end(pid, :gc_minor_end, acc, total_memory(info))

      {:trace, ^pid, :gc_major_start, info} ->
        listen_gc_end(pid, :gc_major_end, acc, total_memory(info))

      :done ->
        exit(:normal)
    end
  end

  defp listen_gc_end(pid, tag, acc, mem_before) do
    receive do
      {:trace, ^pid, ^tag, info} ->
        mem_after = total_memory(info)
        tracer_loop(pid, acc + mem_before - mem_after)
    end
  end

  defp total_memory(info) do
    # `:heap_size` seems to only contain the memory size of the youngest
    # generation `:old_heap_size` has the old generation. There is also
    # `:recent_size` but that seems to already be accounted for.
    Keyword.fetch!(info, :heap_size) + Keyword.fetch!(info, :old_heap_size)
  end
end
