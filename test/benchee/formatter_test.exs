defmodule Benchee.FormatterTest do
  use ExUnit.Case, async: true
  alias Benchee.{Suite, Formatter, Test.FakeFormatter}

  describe "output/1" do
    test "calls `write/1` with the output of `format/1` on each module" do
      Formatter.output(%Suite{configuration: %{formatters: [{FakeFormatter, %{}}]}})

      assert_receive {:write, "output of `format/1` with %{}"}
    end

    test "works with just modules without option tuple" do
      Formatter.output(%Suite{configuration: %{formatters: [FakeFormatter]}})

      assert_receive {:write, "output of `format/1` with %{}"}
    end

    test "options are passed on correctly" do
      Formatter.output(%Suite{configuration: %{formatters: [{FakeFormatter, %{a: :b}}]}})

      assert_receive {:write, "output of `format/1` with %{a: :b}"}
    end

    test "keyword list options are deep converted to maps" do
      Formatter.output(%Suite{configuration: %{formatters: [{FakeFormatter, [a: [b: :c]]}]}})

      assert_receive {:write, "output of `format/1` with %{a: %{b: :c}}"}
    end

    test "mixing functions and formatters works" do
      suite = %Suite{
        configuration: %{
          formatters: [
            {FakeFormatter, %{}},
            fn suite -> send(self(), {:fun, suite, "me"}) end
          ]
        }
      }

      Formatter.output(suite)

      assert_receive {:write, "output of `format/1` with %{}"}
      assert_receive {:fun, ^suite, "me"}
    end

    test "returns the suite passed in as the first argument unchanged" do
      suite = %Suite{configuration: %{formatters: [{FakeFormatter, %{}}]}}
      assert Formatter.output(suite) == suite
    end
  end
end
