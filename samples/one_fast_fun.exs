# Also way too fast and therefore not super feasible, more a test if
# if benchmarking super fast functions has gotten any better.
Benchee.run(%{time: 1}, [{"fast", fn -> 1 + 1 end}])

# tobi@happy ~/github/benchee $ mix run samples/one_fast_fun.exs 
# Benchmarking fast...
# Warning: The function you are trying to benchmark is super fast, making time measures unreliable!
# Benchee won't measure individual runs but rather run it a couple of times and report the average back. Measures will still be correct, but the overhead of running it n times goes into the measurement. Also statistical results aren't as good, as they are based on averages now. If possible, increase the input size so that an individual run takes more than 10μs
#
#
# Name                          ips            average        deviation      median
# fast                          79543147.74    0.0126μs       (±23.29%)      0.0120μs
