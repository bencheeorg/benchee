# Original code by Michal Muskala
# https://gist.github.com/michalmuskala/5ff53581b4b53adec2fff7fb4d69fd52
defmodule BenchKeyword do
  @compile :inline_list_funcs

  @moduledoc """
  Together with the benchmark illustrated multiple problems in the memory measurement code.
  """

  def delete_v0(keywords, key) when is_list(keywords) and is_atom(key) do
    :lists.filter(fn {k, _} -> k != key end, keywords)
  end

  def delete_v2(keywords, key) when is_list(keywords) and is_atom(key) do
    delete_v2_key(keywords, key, [])
  end

  defp delete_v2_key([{key, _} | tail], key, heads) do
    delete_v2_key(tail, key, heads)
  end

  defp delete_v2_key([{_, _} = pair | tail], key, heads) do
    delete_v2_key(tail, key, [pair | heads])
  end

  defp delete_v2_key([], _key, heads) do
    :lists.reverse(heads)
  end

  def delete_v3(keywords, key) when is_list(keywords) and is_atom(key) do
    case :lists.keymember(key, 1, keywords) do
      true -> delete_v3_key(keywords, key, [])
      _ -> keywords
    end
  end

  defp delete_v3_key([{key, _} | tail], key, heads) do
    delete_v3_key(tail, key, heads)
  end

  defp delete_v3_key([{_, _} = pair | tail], key, heads) do
    delete_v3_key(tail, key, [pair | heads])
  end

  defp delete_v3_key([], _key, heads) do
    :lists.reverse(heads)
  end
end
