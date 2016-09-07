# Deactivate the fast warnings if they annoy you
# You can also deactivate the comparison report
Benchee.run(%{
                time: 1,
                print: %{
                  fast_warning: false,
                  comparison: false,
                  configuration: false
                }
              },
            %{"fast" => fn -> 1 + 1 end,
              "also" => fn -> 20 * 20 end
            })

# tobi@airship ~/github/benchee $ mix run samples/deactivate_output.exs
# Benchmarking also...
# Benchmarking fast...
#
# Name           ips        average    deviation         median
# fast   68351710.36       0.0146μs    (±23.14%)       0.0140μs
# also   67527366.91       0.0148μs    (±27.62%)       0.0140μs
