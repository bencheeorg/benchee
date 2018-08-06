defmodule Benchee.Formatter do
  @moduledoc """
  Defines a behaviour for formatters in Benchee, and also defines functions to
  handle invoking that defined behavior.

  When implementing a benchee formatter as a behaviour please adopt this
  behaviour, as it helps with uniformity and also allows at least the `.format`
  function of formatters to be run in parallel.

  Even better, do `use Benchee.Formatter` which will already implement
  the `output/1` function for you. This is recommended as `output/1`
  really shouldn't have any more logic than that, logic/features should
  be in either `format/1` or `write/1`.
  """

  alias Benchee.{Suite, Utility.Parallel}
  alias Benchee.Utility.DeepConvert

  @type options :: any

  @doc """
  Takes the suite and returns whatever representation the formatter wants to use
  to output that information. It is important that this function **needs to be
  pure** (aka have no side effects) as benchee will run `format/1` functions
  of multiple formatters in parallel. The result will then be passed to
  `write/1`.
  """
  @callback format(Suite.t(), options) :: any

  @doc """
  Takes the return value of `format/1` and then performs some I/O for the user
  to actually see the formatted data (UI, File IO, HTTP, ...)
  """
  @callback write(any, options) :: :ok | {:error, String.t()}

  @typep module_configuration :: module | {module, options}

  @doc """
  Format and output all configured formatters and formatting functions.

  Expects a suite that already has been run through all previous functions so has the aggregated
  statistics etc. that the formatters rely on.

  Works by invoking the `format/2` and `write/2` functions defined in this module. The `format/2`
  functions are actually called in parallel (as they should be pure) - due to potential
  interference the `write/2` functions are called serial.

  Also handles   pure functions that will then be called with the suite.

  Actually, you shouldn't rely on this function. Maybe we should move it somewhere else :D
  """
  @spec output(Suite.t()) :: Suite.t()
  def output(suite = %{configuration: %{formatters: formatters}}) do
    {parallelizable, serial} =
      formatters
      |> Enum.map(&normalize_module_configuration/1)
      |> Enum.split_with(&is_formatter_module?/1)

    # why do we ignore this suite? It shouldn't be changed anyway.
    # We assign it because dialyzer would complain otherwise :D
    _suite = parallel_output(suite, parallelizable)

    Enum.each(serial, fn function -> function.(suite) end)

    suite
  end

  @spec output(Suite.t(), module, options) :: Suite.t()
  def output(suite, formatter, options) do
    :ok =
      suite
      |> formatter.format(options)
      |> formatter.write(options)

    suite
  end

  @default_opts %{}
  defp normalize_module_configuration(module_configuration)
  defp normalize_module_configuration({module, opts}), do: {module, DeepConvert.to_map(opts)}

  defp normalize_module_configuration(formatter) when is_atom(formatter) do
    {formatter, @default_opts}
  end

  defp normalize_module_configuration(formatter), do: formatter

  defp is_formatter_module?({formatter, _options}) when is_atom(formatter) do
    module_attributes = formatter.module_info(:attributes)

    module_attributes
    |> Keyword.get(:behaviour, [])
    |> Enum.member?(Benchee.Formatter)
  end

  defp is_formatter_module?(_), do: false

  # Invokes `format/2` and `write/2` as defined by the `Benchee.Formatter`
  # behaviour. The output for all formatters is generated in parallel, and then
  # the results of that formatting are written in sequence.
  @spec parallel_output(Suite.t(), [module_configuration]) :: Suite.t()
  defp parallel_output(suite, module_configurations) do
    module_configurations
    |> Parallel.map(fn {module, options} -> {module, options, module.format(suite, options)} end)
    |> Enum.each(fn {module, options, output} -> module.write(output, options) end)

    suite
  end
end
