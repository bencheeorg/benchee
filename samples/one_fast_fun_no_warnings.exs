# Deactivate the fast warnings if they annoy you
Benchee.run(%{time: 1, print: %{fast_warning: false}},
            %{"fast" => fn -> 1 + 1 end})

# tobi@speedy ~/github/benchee $ mix run samples/one_fast_fun_no_warnings.exs 
# Benchmark suite executing with the following configuration:
# warmup: 2.0s
# time: 1.0s
# parallel: 1
# Estimated total run time: 3.0s
#
# Benchmarking fast...
#
# Name           ips        average    deviation         median
# fast   51132911.86       0.0196μs    (±41.92%)       0.0190μs
