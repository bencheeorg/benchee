defmodule Benchee.SaveLoadTest do
  use ExUnit.Case, async: true

  import ExUnit.CaptureIO
  import Benchee.IntegrationHelpers
  import Benchee.TestHelpers
  @test_configuration Benchee.IntegrationHelpers.test_configuration()

  describe "save & load" do
    test "saving the suite to disk and restoring it" do
      save = [save: [path: "save.benchee", tag: "main"]]
      expected_file = "save.benchee"

      try do
        configuration = Keyword.merge(@test_configuration, save)
        map_fun = fn i -> [i, i * i] end
        list = Enum.to_list(1..10_000)

        capture_io(fn ->
          suite =
            Benchee.run(
              %{
                "flat_map" => fn -> Enum.flat_map(list, map_fun) end,
                "map.flatten" => fn -> list |> Enum.map(map_fun) |> List.flatten() end
              },
              configuration
            )

          content = File.read!(expected_file)

          untagged_suite =
            content
            |> :erlang.binary_to_term()
            |> suite_without_scenario_tags()

          assert untagged_suite == without_functions_and_inputs(suite)
        end)

        loaded_output =
          capture_io(fn ->
            Benchee.run(%{}, Keyword.merge(@test_configuration, load: expected_file))
          end)

        readme_sample_asserts(loaded_output, tag_string: " (main)")

        comparison_output =
          capture_io(fn ->
            Benchee.run(
              %{
                "too fast" => fn -> nil end
              },
              Keyword.merge(@test_configuration, load: expected_file)
            )
          end)

        assert comparison_output =~ ~r/^too fast\s+\d+(\.\d+)?.*+$/m

        assert comparison_output =~
                 ~r/^flat_map \(main\)\s+\d+(\.\d+)?.*- \d+.+x slower \+\d+.+s$/m

        assert comparison_output =~
                 ~r/^map\.flatten \(main\)\s+\d+(\.\d+)?.*- \d+.+x slower \+\d+.+s$/m
      after
        if File.exists?(expected_file) do
          File.rm!(expected_file)
        end
      end
    end

    # function and input provide no real benefit for the envisioned use case of comparing outputs
    # what it does is balloon the file size written out and take performance to the groun
    defp without_functions_and_inputs(suite) do
      update_in(suite.scenarios, fn scenarios ->
        Enum.map(scenarios, fn %Benchee.Scenario{} = scenario ->
          %Benchee.Scenario{scenario | function: nil, input: nil}
        end)
      end)
    end

    test " report/1 raises without providing at least a load option" do
      assert_raise(ArgumentError, ~r/load/i, fn -> Benchee.report([]) end)
    end

    test "report/1 saving first and then reporting on it" do
      save = [save: [path: "save.benchee", tag: nil]]
      expected_file = "save.benchee"

      try do
        configuration = Keyword.merge(@test_configuration, save)
        map_fun = fn i -> [i, i * i] end
        list = Enum.to_list(1..10_000)

        capture_io(fn ->
          Benchee.run(
            %{
              "flat_map" => fn -> Enum.flat_map(list, map_fun) end,
              "map.flatten" => fn -> list |> Enum.map(map_fun) |> List.flatten() end
            },
            configuration
          )
        end)

        report_output =
          capture_io(fn ->
            Benchee.report(Keyword.merge(@test_configuration, load: expected_file))
          end)

        # no system information, benchmarking config or progress for omitted steps is printed out
        readme_sample_asserts(report_output, benchmarking_prints: false)
      after
        if File.exists?(expected_file) do
          File.rm!(expected_file)
        end
      end
    end
  end
end
