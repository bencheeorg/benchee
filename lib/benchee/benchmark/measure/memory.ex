defmodule Benchee.Benchmark.Measure.Memory do
  @moduledoc """
  Measure memory consumption of a function.

  Returns `{nil, return_value}` in case the memory measurement went bad.
  """

  @behaviour Benchee.Benchmark.Measure

  def measure(fun) do
    ref = make_ref()
    Process.flag(:trap_exit, true)
    start_runner(fun, ref)
    await_results(nil, ref)
  end

  def await_results(result, ref) do
    receive do
      {:result, new_result} ->
        await_results(new_result, ref)

      {^ref, memory_usage} ->
        return_memory({memory_usage, result})

      :shutdown ->
        nil
    end
  end

  defp start_runner(fun, ref) do
    parent = self()

    spawn_link(fn ->
      tracer = start_tracer(self())

      try do
        measure_memory(fun, tracer, parent)
        word_size = :erlang.system_info(:wordsize)
        memory_used = get_collected_memory(tracer)
        send(parent, {ref, memory_used * word_size})
      catch
        kind, reason ->
          # would love to have this in a separate function, but elixir 1.7 complains
          send(tracer, :done)
          send(parent, :shutdown)
          stacktrace = System.stacktrace()
          IO.puts(Exception.format(kind, reason, stacktrace))
          exit(:normal)
      after
        send(tracer, :done)
      end
    end)
  end

  defp return_memory({memory_usage, result}) when memory_usage < 0, do: {nil, result}
  defp return_memory({memory_usage, result}), do: {memory_usage, result}

  defp measure_memory(fun, tracer, parent) do
    :erlang.garbage_collect()
    send(tracer, :begin_collection)

    receive do
      :ready_to_begin -> nil
    end

    result = fun.()
    send(parent, {:result, result})
    :erlang.garbage_collect()
    send(tracer, :end_collection)

    receive do
      :ready_to_end -> nil
    end
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
