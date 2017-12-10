defmodule Benchee.ScenarioLoaderTest do
  use ExUnit.Case
  import Benchee.ScenarioLoader
  alias Benchee.{Suite, Configuration}
  alias Benchee.Benchmark.{Scenario}

  test "`load` indeed loads scenarios into the suite" do
    scenarios = [%Scenario{tag: "old"}]
    suite = %Suite{scenarios: scenarios}

    try do
      File.write! "save.benchee", :erlang.term_to_binary(suite)
      configuration = %Configuration{load: "save.benchee"}
      new_suite = load %Suite{configuration: configuration}

      assert new_suite.scenarios == scenarios
    after
      if File.exists?("save.benchee"), do: File.rm! "save.benchee"
    end
  end

end
