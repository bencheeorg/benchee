defmodule Benchee.Profile do
  alias Benchee.Output.ProfilePrinter, as: Printer
  alias Benchee.Suite

  defmodule Benchee.UnknownProfilerError do
    defexception message: "error"
  end

  @moduledoc """
  Profiles each scenario after benchmarking them if the `profile_after` option is either set to:
    * `true`,
    * a valid `profiler`,
    * a tuple of a valid `profiler` and a list of options to pass to it, e.g., `{:fprof, [sort: :own]}`.

  The profiler that will be used is either the one set by the `profiler_after` option or, if set to `true`,
  the default one (`:cprof`). It accepts however the following profilers:
    * `:cprof` will profile with `Mix.Task.Profile.Cprof`. It provides information related to the
    number of function calls.
    * `:eprof` will profile with `Mix.Task.Profile.Eprof`. It provides information related to the
    time spent on each function in regard to the total execution time.
    * `:fprof` will profile with `Mix.Task.Profile.Fprof`. It provides information related to the
    time spent on each function, both the *total* time spent on it and the time spent on it,
    *excluding* the time of called functions.
  """

  @doc """
  Runs for each scenario found in the suite the `profile/2` function from the given profiler.
  """
  @default_profiler :cprof
  @spec profile(Suite.t()) :: Suite.t()
  def profile(suite, printer \\ Printer)
  def profile(suite = %{configuration: %{profile_after: false}}, _printer), do: suite

  def profile(suite = %{configuration: %{profile_after: true}}, printer) do
    config = %{suite.configuration | profile_after: {@default_profiler, []}}

    %{suite | configuration: config}
    |> do_profile(printer)
  end

  def profile(suite = %{configuration: %{profile_after: profiler}}, printer)
      when is_tuple(profiler) do
    do_profile(suite, printer)
  end

  def profile(suite = %{configuration: %{profile_after: profiler}}, printer) do
    config = %{suite.configuration | profile_after: {profiler, []}}

    %{suite | configuration: config}
    |> do_profile(printer)
  end

  defp do_profile(
         suite = %{
           configuration: %{profile_after: {profiler, profiler_opts}},
           scenarios: scenarios
         },
         printer
       ) do
    profiler_module = profiler_to_module(profiler)

    Enum.each(scenarios, fn scenario ->
      run(scenario, {profiler, profiler_module, profiler_opts}, printer)
    end)

    suite
  end

  defp run(
         %{name: name, function: fun_to_profile},
         {profiler, profiler_module, profiler_opts},
         printer
       ) do
    printer.profiling(name, profiler)
    apply(profiler_module, :profile, [fun_to_profile, profiler_opts])
  end

  # If given a builtin profiler the function will return its proper module.
  # In the case of an unknown profiler, it will raise an `UnknownProfilerError` exception.
  defp profiler_to_module(profiler) do
    if is_builtin_profiler(profiler) do
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

  defp is_builtin_profiler(:cprof), do: true
  defp is_builtin_profiler(:eprof), do: true
  defp is_builtin_profiler(:fprof), do: true
  defp is_builtin_profiler(_), do: false
end
