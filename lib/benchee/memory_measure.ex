defmodule Benchee.MemoryMeasure do
  import Kernel, except: [apply: 3, apply: 2]

  def apply(f) do
    apply(:erlang, :apply, [f, []])
  end

  def apply(m, f, a) do
    parent = self()
    ref = make_ref()
    word_size = :erlang.system_info(:wordsize)

    spawn_link(fn ->
      tracer = start_tracer(self())

      try do
        {:garbage_collection_info, info_before} = Process.info(self(), :garbage_collection_info)
        result = Kernel.apply(m, f, a)
        {:garbage_collection_info, info_after} = Process.info(self(), :garbage_collection_info)
        mem_collected = get_collected_memory(tracer)
        final = {result, (info_after[:heap_size] - info_before[:heap_size] + mem_collected) * word_size}
        send(parent, {ref, final})
      after
        send(tracer, :done)
      end
    end)

    receive do
      {^ref, final} -> final
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
