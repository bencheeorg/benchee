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

  @doc """
  Combines `format/1` and `write/1` into a single convenience function that is
  also chainable (as it takes a suite and returns a suite).
  """
  @callback output(Suite.t(), options) :: Suite.t()

  defmacro __using__(_) do
    quote location: :keep do
      @behaviour Benchee.Formatter

      @type options :: any

      @doc """
      Combines `format/1` and `write/1` into a single convenience function that
      is also chainable (as it takes a suite and returns a suite).
      """
      @spec output(Benchee.Suite.t(), options) :: Benchee.Suite.t()
      def output(suite, options \\ %{}) do
        :ok =
          suite
          |> format(options)
          |> write(options)

        suite
      end
    end
  end

  @typep module_configuration :: module | {module, options}

  @doc """
  Invokes `format/2` and `write/3` as defined by the `Benchee.Formatter`
  behaviour. The output for all formatters is generated in parallel, and then
  the results of that formatting are written in sequence.
  """
  @spec parallel_output(Suite.t(), [module_configuration]) :: Suite.t()
  def parallel_output(suite, module_configurations) do
    module_configurations
    |> Parallel.map(fn {module, options} -> {module, options, module.format(suite, options)} end)
    |> Enum.each(fn {module, options, output} -> module.write(output, options) end)

    suite
  end
end
