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
        init runntime: 2
      end
    end

    test "it converts input keys to strings" do
      suite = init inputs: %{"map" => %{}, list: []}

      assert %Suite{
        configuration: %{inputs: %{"list" => [], "map" => %{}}}
      } = suite
    end

    test "it loses duplicated inputs keys after normalization" do
      suite = init inputs: %{"map" => %{}, map: %{}}

      assert %Suite{configuration: %{inputs: inputs}} = suite
      assert %{"map" => %{}} == inputs
    end
  end

  describe ".deep_merge behaviour" do
    test "it can be adjusted with a map" do
      user_options = %{
        time: 10,
        formatter_options: %{
          custom: %{option: true},
          console: %{extended_options: true}
        }
      }

      result = deep_merge(@default_config, user_options)

      expected = %Configuration{
        time: 10,
        formatter_options: %{
          custom: %{option: true},
          console: %{comparison: true, extended_options: true}
        }
      }

      assert ^expected = result
    end

    test "it just replaces when given another configuration" do
      other_config = %Configuration{formatter_options: %{some: %{value: true}}}
      result = deep_merge(@default_config, other_config)
      expected = %Configuration{formatter_options: %{some: %{value: true}}}

      assert  ^expected = result
    end
  end
end
