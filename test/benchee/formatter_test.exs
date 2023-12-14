defmodule Benchee.FormatterTest do
  use ExUnit.Case, async: true
  alias Benchee.{Configuration, Formatter, Suite, Test.FakeFormatter}

  @no_print_assigns %{test: %{progress_printer: Benchee.Test.FakeProgressPrinter}}

  describe "output/1" do
    test "calls `write/1` with the output of `format/1` on each module" do
      Formatter.output(%Suite{
        configuration: %Configuration{
          formatters: [{FakeFormatter, %{}}],
          assigns: @no_print_assigns
        }
      })

      assert_receive {:write, "output of `format/1` with %{}", %{}}
    end

    test "works with just modules without option tuple, defaults to empty map" do
      Formatter.output(%Suite{
        configuration: %Configuration{formatters: [FakeFormatter], assigns: @no_print_assigns}
      })

      assert_receive {:write, "output of `format/1` with %{}", %{}}
    end

    test "options are passed on correctly" do
      Formatter.output(%Suite{
        configuration: %Configuration{
          formatters: [{FakeFormatter, %{a: :b}}],
          assigns: @no_print_assigns
        }
      })

      assert_receive {:write, "output of `format/1` with %{a: :b}", %{a: :b}}
    end

    test "keyword list options are deep converted to maps" do
      Formatter.output(%Suite{
        configuration: %Configuration{
          formatters: [{FakeFormatter, [a: [b: :c]]}],
          assigns: @no_print_assigns
        }
      })

      assert_receive {:write, "output of `format/1` with %{a: %{b: :c}}", %{a: %{b: :c}}}
    end

    test "mixing functions and formatters works" do
      suite = %Suite{
        configuration: %Configuration{
          formatters: [
            {FakeFormatter, %{}},
            fn suite -> send(self(), {:fun, suite, "me"}) end
          ],
          assigns: @no_print_assigns
        }
      }

      Formatter.output(suite)

      assert_receive {:write, "output of `format/1` with %{}", %{}}
      assert_receive {:fun, ^suite, "me"}
    end

    test "mixing functions and formatters works, even with multiple ones" do
      suite = %Suite{
        configuration: %Configuration{
          formatters: [
            {FakeFormatter, %{}},
            fn suite -> send(self(), {:fun, suite, "me"}) end,
            fn _suite -> send(self(), :more_fun) end,
            {FakeFormatter, %{other: :one}}
          ],
          assigns: @no_print_assigns
        }
      }

      Formatter.output(suite)

      assert_receive {:write, "output of `format/1` with %{}", %{}}
      assert_receive {:fun, ^suite, "me"}
      assert_receive :more_fun
      assert_receive {:write, "output of `format/1` with %{other: :one}", %{}}
    end

    test "no formatters, no problem" do
      suite = %Suite{
        configuration: %Configuration{
          formatters: [],
          assigns: @no_print_assigns
        }
      }

      assert suite == Formatter.output(suite)
    end

    test "returns the suite passed in as the first argument unchanged" do
      suite = %Suite{
        configuration: %Configuration{
          formatters: [{FakeFormatter, %{}}],
          assigns: @no_print_assigns
        }
      }

      assert Formatter.output(suite) == suite
    end

    test "lets you know it starts formatting now" do
      Formatter.output(%Suite{
        configuration: %Configuration{formatters: [], assigns: @no_print_assigns}
      })

      assert_received :formatting
    end
  end
end
