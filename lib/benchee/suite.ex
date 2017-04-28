defmodule Benchee.Suite do
  defstruct [:config, :system, :run_times, :statistics, jobs: %{}]

  @type optional_map :: map | nil
  @type t :: %__MODULE__{
    config: optional_map,
    system: optional_map,
    run_times: optional_map,
    statistics: optional_map,
    jobs: map
  }
end

defimpl DeepMerge.Resolver, for: Benchee.Suite do
  def resolve(original, override = %{__struct__: Benchee.Suite}, resolver) do
    cleaned_override = override
                       |> Map.from_struct
                       |> Enum.reject(fn({_key, value}) -> is_nil(value) end)
                       |> Map.new

    Map.merge(original, cleaned_override, resolver)
  end
  def resolve(_, override, _) do
    override
  end
end
