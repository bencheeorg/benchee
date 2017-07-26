defmodule Benchee.Utility.Parallel do
  @moduledoc false

  @doc """
  A utility function for mapping over an enumerable collection in parallel.
  """
  @spec map(Enum.t, fun) :: list
  def map(collection, func) do
    collection
    |> Enum.map(fn(element) -> Task.async(fn() -> func.(element) end) end)
    |> Enum.map(&Task.await(&1, :infinity))
  end
end
