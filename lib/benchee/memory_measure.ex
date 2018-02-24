defmodule Benchee.MemoryMeasure do
  @moduledoc """
  This exposes two functions, apply/1 and apply/3. Both execute a given function
  and report on the memory used by monitoring the garbage collection process for
  a single process.
  """
  import Kernel, except: [apply: 3, apply: 2]

  @spec apply(fun) :: no_return() | tuple()
  def apply(f) do
    apply(:erlang, :apply, [f, []])
  end

  @spec apply(atom, atom, list) :: no_return() | tuple()
  def apply(m, f, a) do
    ref = make_ref()
    Process.flag(:trap_exit, true)
    start_runner(m, f, a, ref)

    receive do
      {^ref, final} -> final
      :shutdown -> nil
    end
  end

  defp start_runner(m, f, a, ref) do
    parent = self()
    word_size = :erlang.system_info(:wordsize)

    spawn_link(fn ->
      tracer = start_tracer(self())

      try do
        {:garbage_collection_info, info_before} = Process.info(self(), :garbage_collection_info)
        result = Kernel.apply(m, f, a)
        {:garbage_collection_info, info_after} = Process.info(self(), :garbage_collection_info)
        mem_collected = get_collected_memory(tracer)

        final =
          {result, (info_after[:heap_size] - info_before[:heap_size] + mem_collected) * word_size}

        send(parent, {ref, final})
      rescue
        exception ->
          :error
          |> Exception.format(exception)
          |> IO.puts()

          safe_exit(tracer, parent)
      catch
        action, argument ->
          IO.puts("Received `#{action}` with the argument `#{argument}`")

          safe_exit(tracer, parent)
      after
        send(tracer, :done)
      end
    end)
  end

  @spec safe_exit(pid, pid) :: no_return()
  defp safe_exit(tracer, parent) do
    send(tracer, :done)
    send(parent, :shutdown)
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
