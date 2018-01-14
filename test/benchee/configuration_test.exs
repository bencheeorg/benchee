defmodule Benchee.ConfigurationTest do
  use ExUnit.Case, async: true
  doctest Benchee.Configuration

  alias Benchee.{Configuration, Suite}

  import DeepMerge
  import Benchee.Configuration

  @default_config %Configuration{}

  describe ".init/1" do
    test "it crashes for values that are going to be ignored" do
      assert_raise KeyError, fn ->
        init(runntime: 2)
      end
    end

    test "it converts input keys to strings" do
      suite = init(inputs: %{"map" => %{}, list: []})

      assert %Suite{
               configuration: %{inputs: %{"list" => [], "map" => %{}}}
             } = suite
    end

    test "it loses duplicated inputs keys after normalization" do
      suite = init(inputs: %{"map" => %{}, map: %{}})

      assert %Suite{configuration: %{inputs: inputs}} = suite
      assert %{"map" => %{}} == inputs
    end

    test "uses information from :save to setup the external term formattter" do
      suite = init(save: [path: "save_one.benchee", tag: "master"])

      assert suite.configuration.formatters == [
               Benchee.Formatters.Console,
               Benchee.Formatters.TaggedSave
             ]

      assert suite.configuration.formatter_options.tagged_save == %{
               path: "save_one.benchee",
               tag: "master"
             }
    end

    test ":save tag defaults to date" do
      suite = init(save: [path: "save_one.benchee"])

      etf_options = suite.configuration.formatter_options.tagged_save

      assert etf_options.tag =~ ~r/\d\d\d\d-\d\d?-\d\d?--\d\d?-\d\d?-\d\d?/
      assert etf_options.path == "save_one.benchee"
    end
  end

  describe ".deep_merge behaviour" do
    test "it can be adjusted with a map" do
      user_options = %{
        time: 10,
        formatter_options: %{
          custom: %{option: true},
          console: %{extended_statistics: true}
        }
      }

      result = deep_merge(@default_config, user_options)

      expected = %Configuration{
        time: 10,
        formatter_options: %{
          custom: %{option: true},
          console: %{comparison: true, extended_statistics: true}
        }
      }

      assert ^expected = result
    end

    test "it just replaces when given another configuration" do
      other_config = %Configuration{formatter_options: %{some: %{value: true}}}
      result = deep_merge(@default_config, other_config)
      expected = %Configuration{formatter_options: %{some: %{value: true}}}

      assert ^expected = result
    end
  end
end
