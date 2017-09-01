defmodule Benchee.Formatter do
  @moduledoc """
  Defines a behaviour for formatters in Benchee, and also defines functions to
  handle invoking that defined behavior.
  """

  alias Benchee.{Suite, Utility.Parallel}

  @callback output(Suite.t) :: Suite.t
  @callback format(Suite.t) :: any
  @callback write(any) :: :ok | {:error, String.t}

  @doc """
  Invokes `format/1` and `write/1` as defined by the `Benchee.Formatter`
  behaviour. The output for all formatters are generated in parallel, and then
  the results of that formatting are written in sequence.
  """
  @spec parallel_output(Suite.t, [module]) :: Suite.t
  def parallel_output(suite, modules) do
    modules
    |> Parallel.map(fn(module) -> {module, module.format(suite)} end)
    |> Enum.each(fn({module, output}) -> module.write(output) end)

    suite
  end
end
