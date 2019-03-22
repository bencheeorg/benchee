defmodule Benchee.ScenarioLoader do
  @moduledoc """
  Load scenarios that were saved using the saved option to be included.

  Usually this is done right before the formatters run (that's when it happens
  in `Benchee.run/2`) as all measurements and statistics should be there.
  However, if you want to recompute statistics or others you can load them at
  any time. Just be aware that if you load them before `Benchee.collect/1` then
  they'll be rerun and measurements overridden.
  """

  alias Benchee.Suite

  @doc """
  Load the file(s) specified as `load_path` and add the scenarios to the list of the
  current scenarios in the suite.
  """
  def load(suite = %{configuration: %{load: load_path}, scenarios: scenarios}) do
    loaded = load_scenarios(load_path)
    %Suite{suite | scenarios: scenarios ++ loaded}
  end

  defp load_scenarios(false), do: []
  defp load_scenarios(path) when is_binary(path), do: load_scenarios([path])

  defp load_scenarios(paths) do
    Enum.flat_map(paths, fn path_or_glob ->
      Enum.flat_map(Path.wildcard(path_or_glob), &load_scenario/1)
    end)
  end

  defp load_scenario(path) do
    loaded_suite =
      path
      |> File.read!()
      |> :erlang.binary_to_term()

    loaded_suite.scenarios
  end
end
