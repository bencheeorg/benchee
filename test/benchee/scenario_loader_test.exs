defmodule Benchee.ScenarioLoaderTest do
  use ExUnit.Case
  import Benchee.ScenarioLoader
  alias Benchee.{Configuration, Scenario, Suite}

  test "`load` indeed loads scenarios into the suite" do
    scenarios = [%Scenario{tag: "old"}]
    suite = %Suite{scenarios: scenarios}

    File.write!("save.benchee", :erlang.term_to_binary(suite))
    configuration = %Configuration{load: "save.benchee"}
    new_suite = load(%Suite{configuration: configuration})

    assert new_suite.scenarios == scenarios
  after
    if File.exists?("save.benchee"), do: File.rm!("save.benchee")
  end

  test "`load` with a list of files" do
    scenarios1 = [%Scenario{tag: "one"}]
    scenarios2 = [%Scenario{tag: "two"}]
    suite1 = %Suite{scenarios: scenarios1}
    suite2 = %Suite{scenarios: scenarios2}

    File.write!("save1.benchee", :erlang.term_to_binary(suite1))
    File.write!("save2.benchee", :erlang.term_to_binary(suite2))

    configuration = %Configuration{load: ["save1.benchee", "save2.benchee"]}
    new_suite = load(%Suite{configuration: configuration})

    assert new_suite.scenarios == scenarios1 ++ scenarios2
  after
    if File.exists?("save1.benchee"), do: File.rm!("save1.benchee")
    if File.exists?("save2.benchee"), do: File.rm!("save2.benchee")
  end

  test "`load` with a glob" do
    scenarios1 = [%Scenario{tag: "one"}]
    scenarios2 = [%Scenario{tag: "two"}]
    suite1 = %Suite{scenarios: scenarios1}
    suite2 = %Suite{scenarios: scenarios2}

    File.write!("save1.benchee", :erlang.term_to_binary(suite1))
    File.write!("save2.benchee", :erlang.term_to_binary(suite2))

    configuration = %Configuration{load: "save*.benchee"}
    new_suite = load(%Suite{configuration: configuration})

    new_tags = Enum.map(new_suite.scenarios, fn scenario -> scenario.tag end)
    assert Enum.sort(new_tags) == ["one", "two"]
  after
    if File.exists?("save1.benchee"), do: File.rm!("save1.benchee")
    if File.exists?("save2.benchee"), do: File.rm!("save2.benchee")
  end
end
