defmodule Benchee.Utility.Task do
  @moduledoc """
  So far this is the best way we have of controlling the effects of garbage
  collection. We essentially re-implement the behavior of `Task.async/1` and
  `Task.await/2` with our own spawning and monitoring of processes so we can use
  Erlang's `erlang.spawn_opt/2` to control the garbage collection settings.
  """

  @doc """
  Start a process that executes a function and  sends the result back to the
  calling process
  """
  @spec async(fun) :: {pid, reference}
  def async(fun) do
    me = self()

    Process.spawn(fn -> send(me, {self(), fun.()}) end, [
      :monitor,
      {:fullsweep_after, 999_999_999_999},
      {:min_heap_size, 999_999_999_999}
    ])
  end

  @doc """
  Waits for a given task to finish and returns the result.

  ## Examples

      iex> task = Benchee.Utility.Task.async(fn -> 1 + 1 end)
      iex> Benchee.Utility.Task.await(task, 5000)
      2

  """
  @spec await({pid, reference}, non_neg_integer | atom) :: any | no_return
  def await({pid, ref}, timeout \\ 5000) do
    receive do
      {:DOWN, ^ref, proc, _, reason} ->
        exit({{reason, proc}, {__MODULE__, :await, [pid, timeout]}})

      {^pid, reply} ->
        Process.demonitor(ref, [:flush])
        reply
    after
      timeout ->
        Process.demonitor(ref, [:flush])
        exit({:timeout, {__MODULE__, :await, [pid, timeout]}})
    end
  end
end
