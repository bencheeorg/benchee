defmodule Benchee.Utility.DeepConvert do
  @moduledoc false

  @doc """
  Converts a deep keywordlist to the corresponding deep map.

  ## Examples

  iex> Benchee.Utility.DeepConvert.to_map([a: 1, b: 2])
  %{a: 1, b: 2}

  iex> Benchee.Utility.DeepConvert.to_map([a: [b: 2], c: [d: 3, e: 4, e: 5]])
  %{a: %{b: 2}, c: %{d: 3, e: 5}}

  iex> Benchee.Utility.DeepConvert.to_map([a: [b: 2], c: [1, 2, 3], d: []])
  %{a: %{b: 2}, c: [1, 2, 3], d: []}

  iex> Benchee.Utility.DeepConvert.to_map(%{a: %{b: 2}, c: %{d: 3, e: 5}})
  %{a: %{b: 2}, c: %{d: 3, e: 5}}

  iex> Benchee.Utility.DeepConvert.to_map([])
  %{}
  """
  def to_map([]), do: %{}
  def to_map(structure), do: do_to_map(structure)

  defp do_to_map(kwlist = [{_key, _value} | _tail]) do
    kwlist
    |> Enum.map(fn({key, value}) -> {key, do_to_map(value)} end)
    |> Map.new
  end
  defp do_to_map(no_list), do: no_list

end
