defmodule Benchee.FormatterTest do
  use ExUnit.Case, async: true
  alias Benchee.{Suite, Formatter, Test.FakeFormatter}

  @suite %Suite{}
  describe "parallel_output/2" do
    test "calls `write/1` with the output of `format/1` on each module" do
      Formatter.parallel_output(@suite, [FakeFormatter])

      assert_receive {:write, "output of `format/1`"}
    end

    test "returns the suite passed in as the first argument unchanged" do
      assert Formatter.parallel_output(@suite, [FakeFormatter]) == @suite
    end
  end
end
