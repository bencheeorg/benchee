defmodule Benchee.Formatter do
  @moduledoc """
  Defines a behaviour for formatters in Benchee, and functions to work with these.

  When implementing a Benchee formatter as a behaviour please adopt this
  behaviour, as it helps with uniformity and also allows at least the `.format`
  function of formatters to be run in parallel.

  The module itself then has functions to deal with formatters defined in this way
  allowing for parallel output through `output/1` or just output a single formatter
  through `output/3`.
  """

  alias Benchee.Output.ProgressPrinter
  alias Benchee.{Scenario, Suite, Utility.Parallel}
  alias Benchee.Utility.DeepConvert

  @typedoc """
  Options given to formatters, entirely defined by formatter authors.
  """
  @type options :: any

  @typedoc """
  A suite scrubbed of heavy data.

  Type to bring awareness to the fact that `format/2` doesn't have access to
  _all_ data in `Benchee.Suite` - please read the docs for `format/2` to learn
  more.
  """
  @type scrubbed_suite :: Suite.t()

  @doc """
  Takes a suite and returns a representation `write/2` can use.

  Takes the suite and returns whatever representation the formatter wants to use
  to output that information. It is important that this function **needs to be
  pure** (aka have no side effects) as Benchee will run `format/1` functions
  of multiple formatters in parallel. The result will then be passed to
  `write/2`.

  **Note:** Due to memory consumption issues in benchmarks with big inputs, the suite
  passed to the formatters **is missing anything referencing big input data** to avoid
  huge memory consumption and run time. Namely this constitutes:
  * `Benchee.Scenario` will have `function` and `input` set to `nil`
  * `Benchee.Configuration` will have `inputs`, but it won't have values only the names,
  it may be removed in the future please use `input_names` instead if needed (or
  `input_name` of `Benchee.Scenario`)

  Technically speaking this "scrubbing" of `Benchee.Suite` only occurs when formatters
  are run in parallel, you still shouldn't rely on those values (and they should not
  be needed). If you do need them for some reason, please get in touch/open an issue.
  """
  @callback format(Suite.t(), options) :: any

  @doc """
  Takes the return value of `format/1` and then performs some I/O for the user
  to actually see the formatted data (UI, File IO, HTTP, ...)
  """
  @callback write(any, options) :: :ok | {:error, String.t()}

  @doc """
  Format and output all configured formatters and formatting functions.

  Expects a suite that already has been run through all previous functions so has the aggregated
  statistics etc. that the formatters rely on.

  Works by invoking the `format/2` and `write/2` functions defined in this module. The `format/2`
  functions are actually called in parallel (as they should be pure) - due to potential
  interference the `write/2` functions are called serial.

  Also handles pure functions that will then be called with the suite.

  You can't rely on the formatters being called in pre determined order.
  """
  @spec output(Suite.t()) :: Suite.t()
  def output(suite = %{configuration: %{formatters: formatters}}) do
    print_formatting(suite.configuration)

    {parallelizable, serial} =
      formatters
      |> Enum.map(&normalize_module_configuration/1)
      |> Enum.split_with(&is_tuple/1)

    maybe_parallel_output(suite, parallelizable)

    Enum.each(serial, fn function -> function.(suite) end)

    suite
  end

  # This is a bit of a hack, but we can't DI the printer like we usually do as we made the _great_
  # decisions to use both `output/1` and `output/2` as part of the public interface. Adding the
  # printer to `output/1` would clash with `output/2` and its second parameter is _also_ a module.
  # So, we're abusing the `assigns` in the config a bit.
  defp print_formatting(config) do
    printer = config.assigns[:test][:progress_printer] || ProgressPrinter
    printer.formatting(config)
  end

  defp normalize_module_configuration(formatter) when is_function(formatter, 1), do: formatter

  defp normalize_module_configuration({module, opts}) do
    normalize_module_configuration(module, DeepConvert.to_map(opts))
  end

  defp normalize_module_configuration(module) when is_atom(module) do
    normalize_module_configuration(module, %{})
  end

  defp normalize_module_configuration(module, opts) do
    if formatter_module?(module) do
      {module, opts}
    else
      raise_behaviour_not_implemented(module)
    end
  end

  defp formatter_module?(module) do
    :attributes
    |> module.module_info()
    |> Keyword.get(:behaviour, [])
    |> Enum.member?(Benchee.Formatter)
  end

  @spec raise_behaviour_not_implemented(atom) :: no_return()
  defp raise_behaviour_not_implemented(module) do
    raise """
    The module you're attempting to use as a formatter - #{module} - does
    not implement the `Benchee.Formatter` behaviour.
    """
  end

  @doc """
  Output a suite with a given formatter and options.

  Replacement for the old `MyFormatter.output/1` - calls `format/2` and `write/2` one after another
  to create the output defined by the given formatter module. For the given options please refer
  to the documentation of the formatters you use.
  """
  @spec output(Suite.t(), module, options) :: Suite.t()
  def output(suite, formatter, options \\ %{}) do
    :ok =
      suite
      |> formatter.format(options)
      |> formatter.write(options)

    suite
  end

  # Invokes `format/2` and `write/2` as defined by the `Benchee.Formatter`
  # behaviour. The output for all formatters is generated in parallel, and then
  # the results of that formatting are written in sequence.
  # If there is only one parallelizable formatter (common case) we don't do it
  # in parallel at all to avoid the cost of copying all the data to a new process
  # (and of us scrubbing it so we don't need as much data)
  defp maybe_parallel_output(suite, module_configurations) do
    module_configurations
    |> maybe_parallel_format(suite)
    |> Enum.each(fn {module, options, output} -> module.write(output, options) end)

    suite
  end

  # don't let it drop to the `Parallel` case so we don't do the scrubbing
  # for nothing
  defp maybe_parallel_format([], _suite), do: []

  defp maybe_parallel_format(formatters = [_one_formatter], suite) do
    Enum.map(formatters, fn {module, options} ->
      {module, options, module.format(suite, options)}
    end)
  end

  defp maybe_parallel_format(formatters, suite) do
    # suite only needs scrubbing for parallel processing due to data copying
    scrubbed_suite = scrub_suite(suite)

    Parallel.map(formatters, fn {module, options} ->
      {module, options, module.format(scrubbed_suite, options)}
    end)
  end

  # The actual benchmarking functions and the actual inputs should not be important for
  # formatters (famous last words, I know) and processing them in parallel means that for
  # benchmarks with a lot of data we end up doing a lot of copying with huge impact on run
  # time and memory consumption.
  # As the suite isn't actually returned from the formatters removing them also doesn't impact
  # anyone negatively downstream.
  # Hence, we scrub them away here. If you maintain a formatter plugin and rely on these please
  # get in touch so we can work on a solution.
  defp scrub_suite(suite) do
    suite =
      update_in(suite.scenarios, fn scenarios ->
        Enum.map(scenarios, &scrub_scenario/1)
      end)

    update_in(suite.configuration, &scrub_configuration/1)
  end

  defp scrub_scenario(scenario) do
    %Scenario{scenario | function: nil, input: nil}
  end

  defp scrub_configuration(configuration) do
    update_in(configuration.inputs, &scrub_inputs/1)
  end

  defp scrub_inputs(nil), do: nil
  # Feels somewhat hacky, but while people should not be relying on the input itself, they
  # may be relying on the input names/order
  defp scrub_inputs(inputs) do
    Enum.map(inputs, fn {name, _value} -> {name, :scrubbed_see_1_3_0_changelog} end)
  end
end
