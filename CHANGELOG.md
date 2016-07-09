# 0.3.0 (unreleased)

## Features

* Benchee now takes a `parallel: number` option and will then execute each job in parallel in as many parallel processes as specified in `number`. This way you can gather more samples in the same time and also simulate a system more under load. This is tricky, however. One of the use cases is also stress testing a system. Thanks @ldr
* the name column width is now determined based on the longest name. Thanks @alvinlindstam

## Bugfixes
* name columns are no longer truncated after 30 characters. Thanks @alvinlindstam

# 0.2.0 (June 11, 2016)

This release introduces warmup for benchmarks, nicer console output and the new `Benchee.measure` that runs the benchmarks previously defined instead of running them instantly.

## Backwards Incompatible Changes

* `Benchee.benchmark/3` now doesn't run the benchmark anymore but simply adds it to `:jobs` in the config. The whole benchmark suite is then run via `Benchee.measure/1`. This only affects you if you used the more verbose way of defining benchmarks, `Benchee.run/2` should still work as expected.
* the defined benchmarking are now preserved after running the benchmark under the `:jobs` key of the suite. Run times are added to the `:run_times` key of the suite (important for alternative statistics implementations)

## Features

* configuring a warmup time to run functions before measurements are taken can be configured via the `warmup` key in the config defaulting to 2 (seconds)
* additionally supply the total standard deviation of iterations per second as `std_dev_ips` after `Benchee.Statistics.statistics`
* statistics in console output are aligned right now for better comparisons
* last blank line of console output removed

## Bugfixes

* if no time/warmup is specified the function won't be called at all

# 0.1.0 (June 5, 2016)

Initial release
