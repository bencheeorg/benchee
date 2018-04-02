defmodule Benchee.Benchmark.Measurer.Memory do
  @moduledoc """
  Measure memory consumption of a function.
  """

  @behaviour Benchee.Benchmark.Measurer

  def measure(fun) do
    ref = make_ref()
    Process.flag(:trap_exit, true)
    start_runner(fun, ref)

    receive do
      {^ref, memory_usage_info} -> memory_usage_info
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

  defp measure_memory(fun, tracer) do
    word_size = :erlang.system_info(:wordsize)
    {:garbage_collection_info, info_before} = Process.info(self(), :garbage_collection_info)
    result = fun.()
    {:garbage_collection_info, info_after} = Process.info(self(), :garbage_collection_info)
    mem_collected = get_collected_memory(tracer)

    {(info_after[:heap_size] - info_before[:heap_size] + mem_collected) * word_size, result}
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
        listen_gc_end(pid, :gc_minor_end, acc, Keyword.fetch!(info, :heap_size))

      {:trace, ^pid, :gc_major_start, info} ->
        listen_gc_end(pid, :gc_major_end, acc, Keyword.fetch!(info, :heap_size))

      :done ->
        exit(:normal)
    end
  end

  defp listen_gc_end(pid, tag, acc, mem_before) do
    receive do
      {:trace, ^pid, ^tag, info} ->
        mem_after = Keyword.fetch!(info, :heap_size)
        tracer_loop(pid, acc + mem_before - mem_after)
    end
  end
end
