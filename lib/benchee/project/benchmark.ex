defmodule Benchee.Project.Benchmark do
  @moduledoc """
  Module with macro for defining project-wide benchmarks.
  """
  require Logger

  def benchee_scenario_attr, do: :benchee_cases

  @doc """
  Module-scope setup. Optional.

  Must return {:ok, state} for actual benchmark to start.
  """
  defmacro setup(_opts \\ [], do: doblock) do
    quote do
      def setup do
        unquote(doblock)
      end
    end
  end

  @doc """
  Module-scope teardown. Optional

  Can return anything.
  """
  defmacro teardown(_opts \\ [], do: doblock) do
    quote do
      def teardown(state) do
        unquote(doblock)
      end
    end
  end

  # credo:disable-for-next-line Credo.Check.Refactor.CyclomaticComplexity
  defmacro benchmark(name, opts \\ [], do: {:__block__, [], exprs}) do
    mod = __CALLER__.module
    state_var = atom_to_var(:state)

    inputs =
      Keyword.get(opts, :inputs, []) ++
        for {:input, _, [name, expr]} <- exprs,
            do:
              {name,
               quote do
                 unquote(block_to_fun(expr)).()
               end}

    case_args =
      case length(inputs) do
        0 -> []
        _ -> [:input]
      end

    scenarios =
      for {:scenario, _, args} <- exprs do
        case args do
          [name, block] ->
            {name, block_to_fun(block, case_args)}

          [name, opts, block] ->
            {name, {block_to_fun(block, case_args), opts}}
        end
      end

    [setup_doblock | rest] =
      (exprs
       |> Enum.filter(fn t -> elem(t, 0) == :setup end)
       |> Enum.map(fn {:setup, _, [[do: doblock]]} -> doblock end)) ++
        [
          quote generated: true do
            {:ok, unquote(state_var)}
          end
        ]

    local_setup = block_to_fun(setup_doblock, [:state])

    if length(rest) > 1 do
      :ok = Logger.warn("#{inspect(mod)}: Only the first setup is used")
    end

    [teardown_doblock | rest] =
      (exprs
       |> Enum.filter(fn t -> elem(t, 0) == :teardown end)
       |> Enum.map(fn {:teardown, _, [[do: doblock]]} -> doblock end)) ++
        [
          quote do
            {:ok, unquote(state_var)}
          end
        ]

    local_teardown = block_to_fun(teardown_doblock, [:state])

    if length(rest) > 1 do
      :ok = Logger.warn("#{inspect(mod)}: Only the first teardown is used")
    end

    opts =
      case inputs do
        [] -> opts
        [_ | _] -> Keyword.put(opts, :inputs, inputs)
      end

    run_fun_name =
      ["run", :erlang.unique_integer() |> Integer.to_string(), name]
      |> Enum.join("_")
      |> String.to_atom()

    quote generated: true do
      @unquote(benchee_scenario_attr())(unquote(run_fun_name))
      def unquote(run_fun_name)(unquote(state_var), opts \\ []) do
        opts = DeepMerge.deep_merge(opts, unquote(opts))

        case unquote(local_setup).(unquote(state_var)) do
          {:ok, unquote(state_var)} ->
            Benchee.run(unquote({:%{}, [], scenarios}), opts)
            unquote(local_teardown).(unquote(state_var))

          other ->
            :ok =
              Logger.error(
                "Local setup of \"#{unquote(name)}\" in " <>
                  "#{inspect(__MODULE__)} returned #{inspect(other)}"
              )
        end
      end
    end
  end

  defmacro __using__(_) do
    quote do
      require Logger

      Module.register_attribute(__MODULE__, unquote(benchee_scenario_attr()),
        persist: true,
        accumulate: true
      )

      import Benchee.Project.Benchmark,
        only: [setup: 1, teardown: 1, benchmark: 2, benchmark: 3]
    end
  end

  # Helpers
  defp quote_put_attrs({name, base_attrs, args}, attrs) do
    {name, Keyword.merge(base_attrs, attrs), args}
  end

  defp atom_to_var(atom, module \\ nil) do
    atom
    |> Macro.var(module)
    |> quote_put_attrs(generated: true)
  end

  %{configuration: %{print: %{system: false}}}

  defp block_to_fun(doblock, args \\ [])

  defp block_to_fun([do: doblock], args),
    do: block_to_fun(doblock, args)

  defp block_to_fun(doblock, args) do
    case Enum.map(args, &atom_to_var/1) do
      [] ->
        quote do
          fn -> unquote(doblock) end
        end

      argvars ->
        quote do
          fn unquote_splicing(argvars) -> unquote(doblock) end
        end
    end
  end
end
