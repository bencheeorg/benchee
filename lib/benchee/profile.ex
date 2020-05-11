defmodule Benchee.Profile do
  @moduledoc """
  Profiles each scenario after benchmarking them if the `profile_after` flag is set to `true`.

  The profiler that will be used is either the one set by the `profiler` option
  in the `profile` configuration or the default one (`:cprof`). It accepts however the following
  profiler options:
    * `:cprof` will profile with `Mix.Task.Profile.Cprof` (useful to discover bottlenecks
    related to function calls).
    * `:eprof` will profile with `Mix.Task.Profile.Eprof` (useful to discover bottlenecks
    related to time information of each function call).
    * `:fprof` will profile with `Mix.Task.Profile.Fprof` (useful to discover bottlenecks
    of a sequential code).
  """
  alias Benchee.Suite

  @doc """
  Runs for each scenario found in the suite the `profile/2` function from the given profiler.
  """
  @spec profile(Suite.t()) :: Suite.t()
  def profile(suite = %{configuration: %{profile: %{profile_after: false}}}), do: suite

  def profile(
        suite = %{
          configuration: %{profile: %{profiler: profiler, profiler_opts: profiler_opts}},
          scenarios: scenarios
        }
      ) do
    profiler_module = profiler_to_module(profiler)

    Enum.each(scenarios, &run(&1, {profiler, profiler_module, profiler_opts}))

    suite
  end

  defp run(%{name: name, function: fun_to_profile}, {profiler, profiler_module, profiler_opts}) do
    IO.puts("\nProfiling #{name} with #{profiler}...")
    apply(profiler_module, :profile, [fun_to_profile, profiler_opts])
  end

  # If given a builtin profiler the function will return its proper module.
  # In the case of an unknown profiler, it will return `nil`
  # (which will make apply/2 crash later).
  defp profiler_to_module(profiler) do
    case is_builtin_profiler(profiler) do
      true ->
        profiler =
          profiler
          |> Atom.to_string()
          |> String.capitalize()

        Module.concat(Mix.Tasks.Profile, profiler)

      false ->
        nil
    end
  end

  defp is_builtin_profiler(:cprof), do: true
  defp is_builtin_profiler(:eprof), do: true
  defp is_builtin_profiler(:fprof), do: true
  defp is_builtin_profiler(_), do: false
end
