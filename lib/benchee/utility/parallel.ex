defmodule Benchee.Utility.Parallel do
  @moduledoc false

  @doc """
  A utility function for mapping over an enumerable collection in parallel.

  Take note that this spawns a process for every element in the collection
  which is only advisable if the function does some heavy lifting.
  """
  @spec map(Enum.t(), fun) :: list
  def map(collection, func) do
    collection
    |> Enum.map(fn element -> Task.async(fn -> func.(element) end) end)
    |> Enum.map(&Task.await(&1, :infinity))
  end
end
