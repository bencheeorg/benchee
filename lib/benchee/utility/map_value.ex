defmodule Benchee.Utility.MapValues do
  @moduledoc false

  @doc """
  Map values of a map keeping the keys intact.

  ## Examples

      iex> Benchee.Utility.MapValues.map_values(%{a: %{b: 2, c: 0}},
      ...> fn(value) -> value + 1 end)
      %{a: %{b: 3, c: 1}}

      iex> Benchee.Utility.MapValues.map_values(%{a: %{b: 2, c: 0}, d: %{e: 2}},
      ...> fn(value) -> value + 1 end)
      %{a: %{b: 3, c: 1}, d: %{e: 3}}
  """
  require IEx
  def map_values(map, function) do
    map
    |> Enum.map(fn({key, child_map}) ->
         {key, do_map_values(child_map, function)}
       end)
    |> Map.new
  end

  defp do_map_values(child_map, function) do
    child_map
    |> Enum.map(fn({key, value}) -> {key, function.(value)} end)
    |> Map.new
  end
end
