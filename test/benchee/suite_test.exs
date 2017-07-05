defmodule Benchee.SuiteTest do
  use ExUnit.Case, async: true

  alias Benchee.{Suite}
  import DeepMerge

  @original %Suite{
    system: %{elixir: "1.4.2", erlang: "19.2"},
    scenarios: []
  }
  describe "deep_merge resolver" do
    test "merges with another Suite rejecting nil values in the override" do
      override = %Suite{
        system: %{elixir: "1.5.0-dev"},
        scenarios: nil
      }

      result = deep_merge(@original, override)
      assert %Suite{
        system: %{elixir: "1.5.0-dev", erlang: "19.2"},
        scenarios: []
      } = result
    end

    test "merges with a map" do
      override = %{
        system: %{elixir: "1.5.0-dev"}
      }

      result = deep_merge(@original, override)

      assert %Suite{
        system: %{elixir: "1.5.0-dev", erlang: "19.2"}
      } = result
    end

    test "raises when anything else is tried" do
      assert_raise FunctionClauseError, fn ->
        deep_merge @original, "lol this doesn't fit"
      end
    end
  end
end
