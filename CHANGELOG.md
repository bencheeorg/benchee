# 0.3.0 (July 11, 2016)

## Breaking Changes (User Facing)
* The recommended data structure handed to `Benchee.run` was changed from a list of 2-element tuples to a map (`"Name" => benchmark_function`). However, **the old list of tuples still works but may be removed in future releases** (so it's not "breaking" _strictly_ speaking).
* You **can not have benchmark jobs with the same names anymore**, the last one wins here. This was the reason why previously the data structure was a list of tuples. However, having benchmarks with the same name is nonsensical as you can't discern their results in the output any way.

## Breaking Changes (Plugins)
* main data structure to hold benchmarks and results was changed from a list of 2-element tuples to a map (`"Name" => values`). That is for the jobs, the run times as well as the statistics. However, if you used something like `Enum.each(data, fn({name, value}) -> .. end)` you are still fine though, cause Elixir is awesome :)

## Features (User Facing)
* now takes a `parallel: number` configuration option and will then execute each job in parallel in as many parallel processes as specified in `number`. This way you can gather more samples in the same time and also simulate a system more under load. This is tricky, however. One of the use cases is also stress testing a system. Thanks @ldr
* the name column width is now determined based on the longest name. Thanks @alvinlindstam
* Print general configuration information at the start of the benchmark, including warmup, time, parallel and an estimated total run time
* New method `Benchee.Formatters.Console.output/1` that immediately prints to the console
* now takes a `formatters: [&My.Format.function/1, &Benchee.Formatters.console.output/1]` configuration option with which multiple formatters for the same benchmarking run can be configured when using `Benchee.run/2`. E.g. you can print results to the console and create a csv from that same run. Defaults to the builtin Console formatter.

## Features (Plugins)
* All previous configuration options are preserved after `Benchee.Statistics.sort/1`, meaning there is access to raw run times as well as custom options etc. E.g. you could grab custom options like `%{csv: %{file: "my_file_name.csv"}}` to use.

## Bugfixes
* name columns are no longer truncated after 30 characters. Thanks @alvinlindstam

# 0.2.0 (June 11, 2016)

This release introduces warmup for benchmarks, nicer console output and the new `Benchee.measure` that runs the benchmarks previously defined instead of running them instantly.

## Breaking Changes (User Facing)
* `Benchee.benchmark/3` now doesn't run the benchmark anymore but simply adds it to `:jobs` in the config. The whole benchmark suite is then run via `Benchee.measure/1`. This only affects you if you used the more verbose way of defining benchmarks, `Benchee.run/2` still work as before.

## Breaking Changes (Plugins)
* the defined benchmarking are now preserved after running the benchmark under the `:jobs` key of the suite. Run times are added to the `:run_times` key of the suite (important for alternative statistics implementations)

## Features (User Facing)

* configuring a warmup time to run functions before measurements are taken can be configured via the `warmup` key in the config defaulting to 2 (seconds)

* statistics in console output are aligned right now for better comparisons
* last blank line of console output removed

## Features (Plugins)
* additionally supply the total standard deviation of iterations per second as `std_dev_ips` after `Benchee.Statistics.statistics`

## Bugfixes

* if no time/warmup is specified the function won't be called at all

# 0.1.0 (June 5, 2016)

Initial release
