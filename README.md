# Benchee [![Hex Version](https://img.shields.io/hexpm/v/benchee.svg)](https://hex.pm/packages/benchee)[![docs](https://img.shields.io/badge/docs-hexpm-blue.svg)](https://hexdocs.pm/benchee/)[![Build Status](https://travis-ci.org/PragTob/benchee.svg?branch=travis)](https://travis-ci.org/PragTob/benchee)

Library for easy and nice (micro) benchmarking. It allows you to easily compare the performance of different pieces of code/functions. Benchee is also versatile and extensible, relying only on functions - no macros!

Somewhat inspired by [benchmark-ips](https://github.com/evanphx/benchmark-ips) from the ruby world, but of course it is a more functional spin.

Provides you with:

* average   - average execution time (the lower the better)
* ips       - iterations per second, how often can the given function be executed within one second (the higher the better)
* deviation - standard deviation (how much do the results vary), given as a percentage of the average
* median    - when all measured times are sorted, this is the middle value (or average of the two middle values when the number of times is even). More stable than the average and somewhat more likely to be a typical you see.

Benchee does not:

* Keep results of previous and compare them, if you want that have a look at [benchfella](https://github.com/alco/benchfella) or [bmark](https://github.com/joekain/bmark)

Make sure to check out the [available plugins](#plugins)!

## Installation

When [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

Add benchee to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:benchee, "~> 0.1.0", only: :dev}]
end
```

Install via `mix deps.get` and then happy benchmarking as described in Usage :)

## Usage

After installing just write a little benchmarking script:

```elixir
list = Enum.to_list(1..10_000)
map_fun = fn(i) -> [i, i * i] end

Benchee.run(%{time: 3},
             [{"flat_map", fn -> Enum.flat_map(list, map_fun) end},
              {"map.flatten",
              fn -> list |> Enum.map(map_fun) |> List.flatten end}])
```

First configuration options are passed, the only option available so far is `time` which is the time in seconds for how long each individual benchmark should run.

Running this scripts produces an output like:

```
tobi@happy ~/github/benchee $ mix run samples/run.exs
Benchmarking flat_map...
Benchmarking map.flatten...

Name                          ips            average        deviation      median
map.flatten                   1311.84        762.29μs       (±13.77%)      747.0μs
flat_map                      896.17         1115.86μs      (±9.54%)       1136.0μs

Comparison:
map.flatten                   1311.84
flat_map                      896.17          - 1.46x slower
```

See the general description for the meaning of the different statistics.

It is important to note that the way shown here is just the convenience interface. The same benchmark in its more verbose form looks like this:

```elixir
list = Enum.to_list(1..10_000)
map_fun = fn(i) -> [i, i * i] end

Benchee.init(%{time: 3})
|> Benchee.benchmark("flat_map", fn -> Enum.flat_map(list, map_fun) end)
|> Benchee.benchmark("map.flatten",
                     fn -> list |> Enum.map(map_fun) |> List.flatten end)
|> Benchee.statistics
|> Benchee.Formatters.Console.format
|> IO.puts
```

This is how the "functional transformation" works here:

1. Configure general parameters
2. run n benchmarks with the given parameters gathering raw run times per function
3. Generate statistics based on the raw run times
4. Format the statistics in a suitable way
5. Output the formatted statistics

This is also part of the official API and allows a more fine grained control.
Do you just want to have all the raw run times? Grab them before `Benchee.statistics`! Just want to have the calculated statistics and use your own formatting? Grab the result of `Benchee.statistics`! Or, maybe you want to write to a file or send an HTTP post to some online service? Just replace the `IO.puts`.

This way Benchee should be flexible enough to suit your needs and be extended at will.

For more example usages and benchmarks have a look at the [`samples`](https://github.com/PragTob/benchee/tree/master/samples) directory!

## Development

* `mix deps.get` to install dependencies
* `mix test` to run tests or `mix test.watch` to run them continuously
* `mix credo` or `mix credo --strict` to find code style problems

Happy to review and accept pull requests or issues :)

## Plugins

Packages that work with Benchee one way or another to enhance its functionality.

* [BencheeCSV](//github.com/PragTob/benchee_csv) - generate CSV from your Benchee benchmark results so you can import them into your favorite spreadsheet tool and make fancy graphs

(You didn't really expect to find tons of plugins here when the library was just released, did you? ;) )
