# When passing a flag parallel with value >1 then multiple processes
# will be handled for benchmarking provided function.

Benchee.run(%{"one" => fn -> :timer.sleep(10) end}, parallel: 1, time: 1)
Benchee.run(%{"three" => fn -> :timer.sleep(10) end}, parallel: 3, time: 1)
Benchee.run(%{"five" => fn -> :timer.sleep(10) end}, parallel: 5, time: 1)

# output doesn't matter here
