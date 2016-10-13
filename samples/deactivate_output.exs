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
# Name           ips        average  deviation         median
# also       90.27 M      0.0111 μs     ±7.60%      0.0110 μs
# fast       90.17 M      0.0111 μs     ±7.94%      0.0110 μs
