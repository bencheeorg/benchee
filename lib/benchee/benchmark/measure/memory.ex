defmodule Benchee.Benchmark.Measure.Memory do
  @moduledoc false

  # Measure memory consumption of a function.
  #
  # Returns `{nil, return_value}` in case the memory measurement went bad.

  @behaviour Benchee.Benchmark.Measure

  def measure(fun) do
    ref = make_ref()
    Process.flag(:trap_exit, true)
    start_runner(fun, ref)

    receive do
      {^ref, memory_usage_info} -> return_memory(memory_usage_info)
      :shutdown -> nil
    end
  end

  defp start_runner(fun, ref) do
    parent = self()

    spawn_link(fn ->
      tracer = start_tracer(self())

      try do
        memory_usage_info = measure_memory(fun, tracer)
        send(parent, {ref, memory_usage_info})
      catch
        kind, reason -> graceful_exit(kind, reason, tracer, parent)
      after
        send(tracer, :done)
      end
    end)
  end

  defp return_memory({memory_usage, result}) when memory_usage < 0, do: {nil, result}
  defp return_memory({memory_usage, result}), do: {memory_usage, result}

  defp measure_memory(fun, tracer) do
    word_size = :erlang.system_info(:wordsize)
    {:garbage_collection_info, heap_before} = Process.info(self(), :garbage_collection_info)
    result = fun.()
    {:garbage_collection_info, heap_after} = Process.info(self(), :garbage_collection_info)
    mem_collected = get_collected_memory(tracer)

    memory_used =
      (total_memory(heap_after) - total_memory(heap_before) + mem_collected) * word_size

    {memory_used, result}
  end

  @spec graceful_exit(Exception.kind(), any(), pid(), pid()) :: no_return
  defp graceful_exit(kind, reason, tracer, parent) do
    send(tracer, :done)
    send(parent, :shutdown)
    stacktrace = System.stacktrace()
    IO.puts(Exception.format(kind, reason, stacktrace))
    exit(:normal)
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
    spawn(fn ->
      :erlang.trace(pid, true, [:garbage_collection, tracer: self()])
      tracer_loop(pid, 0)
    end)
  end

  defp tracer_loop(pid, acc) do
    receive do
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
