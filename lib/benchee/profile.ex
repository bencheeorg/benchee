defmodule Benchee.Profile do
  alias Benchee.Benchmark.Collect
  alias Benchee.Benchmark.RunOnce
  alias Benchee.Benchmark.ScenarioContext
  alias Benchee.Output.ProfilePrinter, as: Printer
  alias Benchee.Suite

  @default_profiler :eprof
  @builtin_profilers [:cprof, :eprof, :fprof]
  # we run the function a bunch already, no need for further warmup
  @default_profiler_opts [warmup: false]

  defmodule Benchee.UnknownProfilerError do
    defexception message: "error"
  end

  @moduledoc """
  Profiles each scenario after benchmarking them if the `profile_after` option is either set to:
    * `true`,
    * a valid `profiler`,
    * a tuple of a valid `profiler` and a list of options to pass to it, e.g., `{:fprof, [sort: :own]}`.

  The profiler that will be used is either the one set by the `profiler_after` option or, if set to `true`,
  the default one (`:eprof`). It accepts however the following profilers:
    * `:cprof` will profile with [`Mix.Task.Profile.Cprof`](https://hexdocs.pm/mix/Mix.Tasks.Profile.Cprof.html).
    It provides information related to the number of function calls.
    * `:eprof` will profile with [`Mix.Task.Profile.Eprof`](https://hexdocs.pm/mix/Mix.Tasks.Profile.Eprof.html).
    It provides information related to the time spent on each function in regard to the total execution time.
    * `:fprof` will profile with [`Mix.Task.Profile.Fprof`](https://hexdocs.pm/mix/Mix.Tasks.Profile.Cprof.html).
    It provides information related to the time spent on each function, both the *total* time spent on it and the time spent on it,
    *excluding* the time of called functions.
  """

  @doc """
  Returns the atom corresponding to the default profiler.
  """
  @spec default_profiler() :: unquote(@default_profiler)
  def default_profiler, do: @default_profiler

  @doc """
  List of supported builtin profilers as atoms.
  """
  def builtin_profilers, do: @builtin_profilers

  @doc """
  Runs for each scenario found in the suite the `profile/2` function from the given profiler.
  """
  @spec profile(Suite.t(), module) :: Suite.t()
  def profile(suite, printer \\ Printer)
  def profile(suite = %{configuration: %{profile_after: false}}, _printer), do: suite

  def profile(
        suite = %{
          scenarios: scenarios,
          configuration: config = %{profile_after: true}
        },
        printer
      ) do
    do_profile(scenarios, {@default_profiler, @default_profiler_opts}, config, printer)

    suite
  end

  def profile(
        suite = %{
          scenarios: scenarios,
          configuration: config = %{profile_after: {profiler, profiler_opts}}
        },
        printer
      ) do
    profiler_opts = Keyword.merge(@default_profiler_opts, profiler_opts)
    do_profile(scenarios, {profiler, profiler_opts}, config, printer)

    suite
  end

  def profile(
        suite = %{
          scenarios: scenarios,
          configuration: config = %{profile_after: profiler}
        },
        printer
      ) do
    do_profile(scenarios, {profiler, @default_profiler_opts}, config, printer)

    suite
  end

  defp do_profile(scenarios, {profiler, profiler_opts}, config, printer) do
    profiler_module = profiler_to_module(profiler)

    Enum.each(scenarios, fn scenario ->
      run(scenario, {profiler, profiler_module, profiler_opts}, config, printer)
    end)
  end

  defp run(
         scenario,
         {profiler, profiler_module, profiler_opts},
         config,
         printer
       ) do
    printer.profiling(scenario.name, profiler)

    RunOnce.run(
      scenario,
      %ScenarioContext{config: config},
      {Collect.Profile, [profiler_module: profiler_module, profiler_opts: profiler_opts]}
    )
  end

  # If given a builtin profiler the function will return its proper module.
  # In the case of an unknown profiler, it will raise an `UnknownProfilerError` exception.
  defp profiler_to_module(profiler) do
    if Enum.member?(@builtin_profilers, profiler) do
      profiler =
        profiler
        |> Atom.to_string()
        |> String.capitalize()

      Module.concat(Mix.Tasks.Profile, profiler)
    else
      raise Benchee.UnknownProfilerError,
        message: "Got an unknown '#{inspect(profiler)}' built-in profiler."
    end
  end
end
