defmodule BenchKeyword do
  @compile :inline_list_funcs

  # def pop_throw(keywords, key, default \\ nil) when is_list(keywords) do
  #   do_pop(keywords, key, [])
  # catch
  #   :not_found -> {default, keywords}
  # end

  # defp do_pop([{key, value} | rest], key, acc),
  #   do: {value, :lists.reverse(acc, delete(rest, key))}
  # defp do_pop([{_, _} = pair | rest], key, acc),
  #   do: do_pop(rest, key, [pair | acc])
  # defp do_pop([], _key, _acc),
  #   do: throw(:not_found)

  # def pop_ret(keywords, key, default \\ nil) when is_list(keywords) do
  #   do_pop(keywords, key, [], keywords, default)
  # end

  # defp do_pop([{key, value} | rest], key, acc, _keywords, _default),
  #   do: {value, :lists.reverse(acc, delete(rest, key))}
  # defp do_pop([{_, _} = pair | rest], key, acc, keywords, default),
  #   do: do_pop(rest, key, [pair | acc], keywords, default)
  # defp do_pop([], _key, _acc, keywords, default),
  #   do: {default, keywords}

  # def pop(keywords, key, default \\ nil) when is_list(keywords) do
  #   case fetch(keywords, key) do
  #     {:ok, value} ->
  #       {value, delete(keywords, key)}
  #     :error ->
  #       {default, keywords}
  #   end
  # end

  # def pop2(keywords, key, default \\ nil) when is_list(keywords) do
  #   case :lists.keyfind(key, 1, keywords) do
  #     {^key, value} -> {value, delete2(keywords, key)}
  #     false -> {default, keywords}
  #   end
  # end

  # def fetch(keywords, key) when is_list(keywords) and is_atom(key) do
  #   case :lists.keyfind(key, 1, keywords) do
  #     {^key, value} -> {:ok, value}
  #     false -> :error
  #   end
  # end

  def delete_v0(keywords, key) when is_list(keywords) and is_atom(key) do
    :lists.filter(fn {k, _} -> k != key end, keywords)
  end

  def delete_v1(keywords, key) when is_list(keywords) and is_atom(key) do
    do_delete(keywords, key, _deleted? = false)
  catch
    :not_deleted -> keywords
  end

  defp do_delete([{key, _} | rest], key, _deleted?),
    do: do_delete(rest, key, true)
  defp do_delete([{_, _} = pair | rest], key, deleted?),
    do: [pair | do_delete(rest, key, deleted?)]
  defp do_delete([], _key, _deleted? = true),
    do: []
  defp do_delete([], _key, _deleted? = false),
    do: throw(:not_deleted)


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

  def delete_v4(keywords, key) when is_list(keywords) and is_atom(key) do
    case :lists.keymember(key, 1, keywords) do
      true -> delete_v4_key(keywords, key)
      _ -> keywords
    end
  end

  defp delete_v4_key([{key, _} | tail], key) do
    delete_v4_key(tail, key)
  end

  defp delete_v4_key([{_, _} = pair | tail], key) do
    [pair | delete_v4_key(tail, key)]
  end

  defp delete_v4_key([], _key) do
    []
  end
end

# benches = %{
#   "pop_throw" => fn {kv, key} -> BenchKeyword.pop_throw(kv, key) end,
#   "pop_ret" => fn {kv, key} -> BenchKeyword.pop_ret(kv, key) end,
#   "pop" => fn {kv, key} -> BenchKeyword.pop(kv, key) end,
#   "pop2" => fn {kv, key} -> BenchKeyword.pop2(kv, key) end
# }

benches = %{
  "delete old" => fn {kv, key} -> BenchKeyword.delete_v0(kv, key) end,
  "delete throw" => fn {kv, key} -> BenchKeyword.delete_v1(kv, key) end,
  "delete reverse" => fn {kv, key} -> BenchKeyword.delete_v2(kv, key) end,
  "delete keymember reverse" => fn {kv, key} -> BenchKeyword.delete_v3(kv, key) end,
  "delete keymember body" => fn {kv, key} -> BenchKeyword.delete_v4(kv, key) end
}

inputs = %{
  "small miss" => {Enum.map(1..10, &{:"k#{&1}", &1}), :k11},
  "small hit" => {Enum.map(1..10, &{:"k#{&1}", &1}), :k10},
  "large miss" => {Enum.map(1..100, &{:"k#{&1}", &1}), :k101},
  "large hit" => {Enum.map(1..100, &{:"k#{&1}", &1}), :k100},
  "huge miss" => {Enum.map(1..10000, &{:"k#{&1}", &1}), :k10001},
  "huge hit" => {Enum.map(1..10000, &{:"k#{&1}", &1}), :k10000}
}

Benchee.run(benches, inputs: inputs, print: [fast_warning: false], memory_time: 0.5, warmup: 0, time: 0)
