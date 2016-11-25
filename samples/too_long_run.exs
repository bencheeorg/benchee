# This is a **bad** example where a single run of the sample takes more time
# than given to the benchmark.

Benchee.run(%{"Job" => fn -> :timer.sleep(1000) end}, warmup: 0, time: 0.5)
