defmodule Benchee.Suite do
  defstruct [:config, :system, :run_times, :statistics, jobs: %{}]

  @type t :: %__MODULE__{config: map, system: map, run_times: map,
                         statistics: map, jobs: map}
end

defimpl DeepMerge.Resolver, for: Benchee.Suite do
  def resolve(original, override = %{__struct__: Benchee.Suite}, resolver) do
    cleaned_override = override
                       |> Map.from_struct
                       |> Enum.reject(fn({key, value}) -> is_nil(value) end)
                       |> Map.new

    Map.merge(original, cleaned_override, resolver)
  end
  def resolve(_, override, _) do
    override
  end
end
