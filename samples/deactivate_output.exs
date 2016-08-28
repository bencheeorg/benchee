# Deactivate the fast warnings if they annoy you
# You can also deactivate the comparison report
Benchee.run(%{time: 1, print: %{fast_warning: false, comparison: false}},
            %{"fast" => fn -> 1 + 1 end,
              "also" => fn -> 20 * 20 end
            })

# tobi@happy ~/github/benchee $ mix run samples/deactivate_output.exs 
# Compiling 7 files (.ex)
# Generated benchee app
# Benchmark suite executing with the following configuration:
# warmup: 2.0s
# time: 1.0s
# parallel: 1
# Estimated total run time: 6.0s
#
# Benchmarking also...
# Benchmarking fast...
#
# Name           ips        average    deviation         median
# also   90164780.87       0.0111μs    (±19.37%)       0.0110μs
# fast   90110136.30       0.0111μs    (±15.08%)       0.0110μs
