defmodule Benchee.Formatters.ConsoleTest do
  use ExUnit.Case, async: true
  doctest Benchee.Formatters.Console, import: true

  import ExUnit.CaptureIO

  alias Benchee.{
    CollectionData,
    Formatter,
    Formatters.Console,
    Scenario,
    Statistics,
    Suite
  }

  @config %Benchee.Configuration{
    title: "A comprehensive benchmarking of inputs"
  }
  @no_input Benchee.Benchmark.no_input()
  @options %{
    comparison: true,
    extended_statistics: false
  }

  describe "Formatter.output/3 integration" do
    test "formats and prints the results right to the console" do
      scenarios = [
        %Scenario{
          name: "First",
          input_name: @no_input,
          input: @no_input,
          run_time_data: %CollectionData{
            statistics: %Statistics{
              average: 100.0,
              ips: 10_000.0,
              std_dev_ratio: 0.1,
              median: 90.0,
              percentiles: %{99 => 300.1},
              sample_size: 200
            }
          },
          memory_usage_data: %CollectionData{statistics: %Statistics{}}
        },
        %Scenario{
          name: "Second",
          input_name: @no_input,
          input: @no_input,
          run_time_data: %CollectionData{
            statistics: %Statistics{
              average: 200.0,
              ips: 5_000.0,
              std_dev_ratio: 0.1,
              median: 195.5,
              percentiles: %{99 => 400.1},
              sample_size: 200,
              relative_more: 2.0,
              absolute_difference: 100.0
            }
          },
          memory_usage_data: %CollectionData{statistics: %Statistics{}}
        }
      ]

      output =
        capture_io(fn ->
          Formatter.output(
            %Suite{scenarios: scenarios, configuration: @config},
            Console,
            @options
          )
        end)

      assert output =~ "First"
      assert output =~ "Second"
      assert output =~ "200"
      assert output =~ "5 K"
      assert output =~ "10.00%"
      assert output =~ "195.5"
      assert output =~ "300.1"
      assert output =~ "400.1"
      assert output =~ "2.00x slower"
      assert output =~ "+100 ns"
    end
  end

  describe "format/2" do
    @header_regex ~r/Name.+ips.+average.+deviation.+median.+99th %.*/
    test "with multiple inputs and just one job" do
      scenarios = [
        %Scenario{
          name: "Job",
          input_name: "My Arg",
          input: "My Arg",
          run_time_data: %CollectionData{
            statistics: %Statistics{
              average: 200.0,
              ips: 5_000.0,
              std_dev_ratio: 0.1,
              median: 195.5,
              percentiles: %{99 => 400.1},
              sample_size: 200
            }
          },
          memory_usage_data: %CollectionData{statistics: %Statistics{}}
        },
        %Scenario{
          name: "Job",
          input_name: "Other Arg",
          input: "Other Arg",
          run_time_data: %CollectionData{
            statistics: %Statistics{
              average: 400.0,
              ips: 2_500.0,
              std_dev_ratio: 0.15,
              median: 395.0,
              percentiles: %{99 => 500.1},
              sample_size: 200
            }
          },
          memory_usage_data: %CollectionData{statistics: %Statistics{}}
        }
      ]

      [my_arg, other_arg] =
        Console.format(%Suite{scenarios: scenarios, configuration: @config}, @options)

      [input_header, header, result] = my_arg
      assert input_header =~ "My Arg"
      assert header =~ @header_regex
      assert result =~ ~r/Job.+5.+200.+10\.00%.+195\.5.+400\.1/

      [input_header_2, header_2, result_2] = other_arg
      assert input_header_2 =~ "Other Arg"
      assert header_2 =~ @header_regex
      assert result_2 =~ ~r/Job.+2\.5.+400.+15\.00%.+395.+500\.1/
    end

    test "retains the order of scenarios" do
      scenarios = [
        %Scenario{
          name: "Job",
          input_name: "Other Arg",
          input: "Other Arg",
          run_time_data: %CollectionData{
            statistics: %Statistics{
              average: 400.0,
              ips: 2_500.0,
              std_dev_ratio: 0.15,
              median: 395.0,
              percentiles: %{99 => 500.1},
              sample_size: 200
            }
          },
          memory_usage_data: %CollectionData{statistics: %Statistics{}}
        },
        %Scenario{
          name: "Job",
          input_name: "My Arg",
          input: "My Arg",
          run_time_data: %CollectionData{
            statistics: %Statistics{
              average: 200.0,
              ips: 5_000.0,
              std_dev_ratio: 0.1,
              median: 195.5,
              percentiles: %{99 => 400.1},
              sample_size: 200
            }
          },
          memory_usage_data: %CollectionData{statistics: %Statistics{}}
        }
      ]

      [other_arg, my_arg] =
        Console.format(%Suite{scenarios: scenarios, configuration: @config}, @options)

      [input_header, header, result] = my_arg
      assert input_header =~ "My Arg"
      assert header =~ @header_regex
      assert result =~ ~r/Job.+5.+200.+10\.00%.+195\.5.+400\.1/

      [input_header_2, header_2, result_2] = other_arg
      assert input_header_2 =~ "Other Arg"
      assert header_2 =~ @header_regex
      assert result_2 =~ ~r/Job.+2\.5.+400.+15\.00%.+395.+500\.1/
    end

    test "with multiple inputs and two jobs" do
      scenarios = [
        %Scenario{
          name: "Other Job",
          input_name: "My Arg",
          input: "My Arg",
          run_time_data: %CollectionData{
            statistics: %Statistics{
              average: 100.0,
              ips: 10_000.0,
              std_dev_ratio: 0.3,
              median: 98.0,
              percentiles: %{99 => 200.1},
              sample_size: 200
            }
          },
          memory_usage_data: %CollectionData{statistics: %Statistics{}}
        },
        %Scenario{
          name: "Job",
          input_name: "My Arg",
          input: "My Arg",
          run_time_data: %CollectionData{
            statistics: %Statistics{
              average: 200.0,
              ips: 5_000.0,
              std_dev_ratio: 0.1,
              median: 195.5,
              percentiles: %{99 => 300.1},
              sample_size: 200,
              relative_more: 2.0,
              absolute_difference: 100.0
            }
          },
          memory_usage_data: %CollectionData{statistics: %Statistics{}}
        },
        %Scenario{
          name: "Other Job",
          input_name: "Other Arg",
          input: "Other Arg",
          run_time_data: %CollectionData{
            statistics: %Statistics{
              average: 250.0,
              ips: 4_000.0,
              std_dev_ratio: 0.31,
              median: 225.5,
              percentiles: %{99 => 300.1},
              sample_size: 200
            }
          },
          memory_usage_data: %CollectionData{statistics: %Statistics{}}
        },
        %Scenario{
          name: "Job",
          input_name: "Other Arg",
          input: "Other Arg",
          run_time_data: %CollectionData{
            statistics: %Statistics{
              average: 400.0,
              ips: 2_500.0,
              std_dev_ratio: 0.15,
              median: 395.0,
              percentiles: %{99 => 500.1},
              sample_size: 200,
              relative_more: 1.6,
              absolute_difference: 150.0
            }
          },
          memory_usage_data: %CollectionData{statistics: %Statistics{}}
        }
      ]

      [my_arg, other_arg] =
        Console.format(%Suite{scenarios: scenarios, configuration: @config}, @options)

      [input_header, _header, other_job, job, _comp, ref, slower] = my_arg
      assert input_header =~ "My Arg"
      assert other_job =~ ~r/Other Job.+10.+100.+30\.00%.+98.+200\.1/
      assert job =~ ~r/Job.+5.+200.+10\.00%.+195\.5/
      ref =~ ~r/Other Job/
      slower =~ ~r/Job.+slower \+100/

      [input_header_2, _, other_job_2, job_2, _, ref_2, slower_2] = other_arg
      assert input_header_2 =~ "Other Arg"
      assert other_job_2 =~ ~r/Other Job.+4.+250.+31\.00%.+225\.5.+300\.1/
      assert job_2 =~ ~r/Job.+2\.5.+400.+15\.00%.+395/
      ref_2 =~ ~r/Other Job/
      slower_2 =~ ~r/Job.+slower \+150/
    end

    test "with and without a tag" do
      scenarios = [
        %Scenario{
          name: "job (improved)",
          input_name: @no_input,
          input: @no_input,
          run_time_data: %CollectionData{
            statistics: %Statistics{
              average: 100.0,
              ips: 10_000.0,
              std_dev_ratio: 0.1,
              median: 90.0,
              percentiles: %{99 => 200.1},
              sample_size: 200
            }
          },
          memory_usage_data: %CollectionData{statistics: %Statistics{}}
        },
        %Scenario{
          name: "job",
          input_name: @no_input,
          input: @no_input,
          run_time_data: %CollectionData{
            statistics: %Statistics{
              average: 200.0,
              ips: 5_000.0,
              std_dev_ratio: 0.1,
              median: 195.5,
              percentiles: %{99 => 300.1},
              sample_size: 200,
              relative_more: 2.0,
              absolute_difference: 100.0
            }
          },
          memory_usage_data: %CollectionData{statistics: %Statistics{}}
        }
      ]

      [result] = Console.format(%Suite{scenarios: scenarios, configuration: @config}, @options)
      [_, _header, job_with_tag, job, _, comparison, _slower] = result

      assert job_with_tag =~ ~r/job \(improved\)\s+10 K/
      assert job =~ ~r/job\s+5 K/
      assert comparison =~ ~r/job \(improved\)\s+ 10 K/
    end

    test "Correctly displays difference even if it is negative" do
      scenarios = [
        %Scenario{
          name: "job",
          input_name: @no_input,
          input: @no_input,
          run_time_data: %CollectionData{
            statistics: %Statistics{
              average: 200.0,
              ips: 5_000.0,
              std_dev_ratio: 0.1,
              median: 195.5,
              percentiles: %{99 => 300.1},
              sample_size: 200
            }
          },
          memory_usage_data: %CollectionData{statistics: %Statistics{}}
        },
        %Scenario{
          name: "job (improved)",
          input_name: @no_input,
          input: @no_input,
          run_time_data: %CollectionData{
            statistics: %Statistics{
              average: 100.0,
              ips: 10_000.0,
              std_dev_ratio: 0.1,
              median: 90.0,
              percentiles: %{99 => 200.1},
              sample_size: 200,
              relative_more: 0.5,
              relative_less: 2.0,
              absolute_difference: -100.0
            }
          },
          memory_usage_data: %CollectionData{statistics: %Statistics{}}
        }
      ]

      [result] = Console.format(%Suite{scenarios: scenarios, configuration: @config}, @options)
      [_, _header, _job_with_tag, _job, _, comparison, slower] = result

      assert comparison =~ ~r/job\s+ 5 K$/
      assert slower =~ ~r/job \(improved\)\s+10 K\s+- 0\.50x slower -100 ns$/
    end

    test "includes the suite's title" do
      scenarios = [
        %Scenario{
          name: "job",
          input_name: @no_input,
          input: @no_input,
          run_time_data: %CollectionData{
            statistics: %Statistics{
              average: 200.0,
              ips: 5_000.0,
              std_dev_ratio: 0.1,
              median: 195.5,
              percentiles: %{99 => 300.1},
              sample_size: 200
            }
          },
          memory_usage_data: %CollectionData{statistics: %Statistics{}}
        }
      ]

      [[title | _]] =
        Console.format(%Suite{scenarios: scenarios, configuration: @config}, @options)

      assert title =~ ~r/A comprehensive benchmarking of inputs/
    end
  end
end
