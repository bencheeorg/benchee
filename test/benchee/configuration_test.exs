defmodule Benchee.ConfigurationTest do
  use ExUnit.Case, async: true
  doctest Benchee.Configuration

  alias Benchee.Configuration

  import DeepMerge
  import Benchee.Configuration

  @default_config %Configuration{}

  describe ".init/1" do
    test "it crashes for values that are going to be ignored" do
      assert_raise KeyError, fn ->
        init runntime: 2
      end
    end
  end

  describe ".deep_merge behaviour" do
    test "it can be adjusted with a map" do
      user_options = %{
        time: 10,
        formatter_options: %{custom: %{option: true}}
      }

      result = deep_merge(@default_config, user_options)

      expected = %Configuration{
        time: 10,
        formatter_options: %{
          custom: %{option: true},
          console: %{
            comparison:    true,
            unit_scaling:  :best
          }
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
