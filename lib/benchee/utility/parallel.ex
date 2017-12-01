defmodule Benchee.Utility.Parallel do
  @moduledoc false
  alias Benchee.Utility.Task, as: BTask

  @doc """
  A utility function for mapping over an enumerable collection in parallel.
  """
  @spec map(Enum.t, fun) :: list
  def map(collection, func) do
    collection
    |> Enum.map(fn(element) -> BTask.async(fn() -> func.(element) end) end)
    |> Enum.map(&BTask.await(&1, :infinity))
  end
end
