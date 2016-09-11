# Deactivate the fast warnings if they annoy you
# You can also deactivate the comparison report
Benchee.run(%{
                time: 1,
                print: %{
                  benchmarking:  false,
                  configuration: false,
                  fast_warning:  false
                },
                console: %{
                  comparison: false
                }
              },
            %{"fast" => fn -> 1 + 1 end,
              "also" => fn -> 20 * 20 end
            })

# tobi@airship ~/github/benchee $ mix run samples/deactivate_output.exs
#
# Name           ips        average    deviation         median
# fast   67196569.41       0.0149μs    (±24.72%)       0.0140μs
# also   66268711.31       0.0151μs    (±24.23%)       0.0140μs
