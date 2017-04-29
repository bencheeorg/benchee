defmodule Benchee.Suite do
  defstruct [:config, :system, :run_times, :statistics, jobs: %{}]

  @type optional_map :: map | nil
  @type key :: atom | String.t
  @type input_key :: key
  @type benchmark_function :: (() -> any) | ((any) -> any)
  @type t :: %__MODULE__{
    config: optional_map,
    system: optional_map,
    run_times: %{input_key => %{key => [integer]}} | nil,
    statistics: %{input_key => %{key => Benchee.Statistics.t}} | nil,
    jobs: %{key => benchmark_function}
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
  def resolve(original, override, resolver) when is_map(override) do
    Map.merge(original, override, resolver)
  end
end
