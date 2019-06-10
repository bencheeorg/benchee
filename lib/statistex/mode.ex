defmodule Statistex.Mode do
  @moduledoc false

  @typedoc """
  Careful with the mode, might be multiple values, one value or nothing.😱
  """
  @type mode :: [number] | number | nil

  @doc """
      iex> Statistex.Mode.mode([5, 3, 4, 5, 1, 3, 1, 3])
      3

      iex> Statistex.Mode.mode([])
      nil

      iex> Statistex.Mode.mode([1, 2, 3, 4, 5])
      nil

      iex> mode = Statistex.Mode.mode([5, 3, 4, 5, 1, 3, 1])
      iex> Enum.sort(mode)
      [1, 3, 5]
  """
  @spec mode(Statistex.samples()) :: mode()
  def(mode(samples)) do
    samples
    |> Enum.reduce(%{}, fn sample, counts ->
      Map.update(counts, sample, 1, fn old_value -> old_value + 1 end)
    end)
    |> max_multiple
    |> decide_mode
  end

  defp max_multiple(map) do
    max_multiple(Enum.to_list(map), [{nil, 0}])
  end

  defp max_multiple([{sample, count} | rest], ref = [{_, max_count} | _]) do
    new_ref =
      cond do
        count < max_count -> ref
        count == max_count -> [{sample, count} | ref]
        true -> [{sample, count}]
      end

    max_multiple(rest, new_ref)
  end

  defp max_multiple([], ref) do
    ref
  end

  defp decide_mode([{nil, _}]), do: nil
  defp decide_mode([{_, 1} | _rest]), do: nil
  defp decide_mode([{sample, _count}]), do: sample

  defp decide_mode(multi_modes) do
    Enum.map(multi_modes, fn {sample, _} -> sample end)
  end
end
