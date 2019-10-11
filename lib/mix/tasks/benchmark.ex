defmodule Mix.Tasks.Benchmark.Helper do
  @moduledoc false
  defmacro compile_file(file) do
    case compare_versions(System.version(), "1.7.0") do
      :gt ->
        quote do
          Code.compile_file(unquote(file))
        end

      _ ->
        quote do
          Code.load_file(unquote(file))
        end
    end
  end

  defp compare_versions(v1, v2) do
    Version.compare(Version.parse!(v1), Version.parse!(v2))
  end
end

defmodule Mix.Tasks.Benchmark do
  use Mix.Task
  require Logger
  alias Mix.Tasks.Benchmark.Helper
  require Mix.Tasks.Benchmark.Helper

  @moduledoc """
  Runs project benchmarks
  """
  @dialyzer [no_match: [find_benchmark_files: 2]]

  @switches []

  @shortdoc "Runs project benchmarks"
  @recursive true
  @preferred_cli_env :test
  @impl Mix.Task
  def run(args) do
    {opts, files} = OptionParser.parse!(args, strict: @switches)

    compile_project(args, opts)

    files
    |> compile_benchmarks(opts)
    |> run_benchmarks(opts)
  end

  defp compile_project(args, _opts) do
    :ok = Logger.debug("Compiling project")
    Mix.Task.run("loadpaths", args)
    Mix.Project.compile(args)
  end

  defp compile_benchmarks(files, opts) do
    files
    |> find_benchmark_files(opts)
    |> compile_benchmark_files(opts)
  end

  defp find_benchmark_files(:stop, _opts), do: :stop

  defp find_benchmark_files(files, _opts) do
    :ok = Logger.debug("Locating benchmarks")

    files =
      case files do
        [] ->
          [default_benchmark_path()]

        o ->
          o
      end

    files =
      Enum.flat_map(files, fn file ->
        if File.dir?(file) do
          [file, "*.exs"]
          |> Path.join()
          |> Path.wildcard()
        else
          [file]
        end
      end)

    case files do
      [] ->
        :ok = Logger.debug("No benchmark files found")
        :stop

      files ->
        files
    end
  end

  defp compile_benchmark_files(:stop, _opts), do: :stop

  defp compile_benchmark_files(files, _opts) do
    :ok = Logger.debug("Compiling benchmarks")

    modules =
      files
      |> Enum.flat_map(fn f ->
        f
        |> Helper.compile_file()
        |> Enum.map(fn {mod, _bin} -> mod end)
      end)

    case modules do
      [] ->
        :ok = Logger.debug("No benchmarks found")
        :stop

      modules ->
        modules
    end
  end

  defp run_benchmarks(:stop, _opts), do: :stop

  defp run_benchmarks(modules, _opts) do
    :ok = Logger.debug("Running benchmarks")

    modules
    |> get_benchmarks()
    |> run_all_benchmarks()
  end

  defp run_all_benchmarks(benchmarks, print_system? \\ true)
  defp run_all_benchmarks([], _print?), do: :ok

  defp run_all_benchmarks([{mod, run_funs} | rest], print_system?) do
    opts =
      case print_system? do
        true -> []
        false -> [print: [system: false]]
      end

    case apply_if_exists(mod, :setup, [], {:ok, nil}) do
      {:ok, state} ->
        state =
          Enum.reduce(run_funs, state, fn funname, state ->
            apply(mod, funname, [state, opts])
          end)

        try_apply_if_exists(mod, :teardown, [state])

      other ->
        :ok =
          Logger.error(
            "Global setup of \"#{inspect(mod)}\" " <>
              "returned #{inspect(other)}"
          )
    end

    run_all_benchmarks(rest, false)
  end

  defp try_apply_if_exists(mod, name, args) do
    case apply_if_exists(mod, name, args) do
      _ -> :ok
    end
  end

  defp apply_if_exists(mod, name, args, default) do
    case apply_if_exists(mod, name, args) do
      {:ok, result} -> result
      {:error, :not_exists} -> default
    end
  end

  defp apply_if_exists(mod, fun, args) do
    arity = length(args)

    case mod.module_info(:exports)[fun] do
      ^arity -> {:ok, apply(mod, fun, args)}
      nil -> {:error, :not_exists}
    end
  end

  defp get_benchmarks(modules) do
    case_attr = Benchee.Project.Benchmark.benchee_scenario_attr()

    modules
    |> Stream.filter(fn mod ->
      Keyword.has_key?(mod.module_info(:attributes), case_attr)
    end)
    |> Stream.map(fn mod ->
      attrs = mod.module_info(:attributes)
      run_funs = Keyword.get(attrs, case_attr)
      {mod, run_funs}
    end)
    |> Enum.to_list()
  end

  def default_benchmark_path do
    "./benchmarks"
  end
end
