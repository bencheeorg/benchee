# Benchee [![Hex Version](https://img.shields.io/hexpm/v/benchee.svg)](https://hex.pm/packages/benchee) [![docs](https://img.shields.io/badge/docs-hexpm-blue.svg)](https://hexdocs.pm/benchee/) [![Inline docs](http://inch-ci.org/github/PragTob/benchee.svg)](http://inch-ci.org/github/PragTob/benchee) [![Build Status](https://travis-ci.org/PragTob/benchee.svg?branch=master)](https://travis-ci.org/PragTob/benchee)

Library for easy and nice (micro) benchmarking in Elixir. It allows you to compare the performance of different pieces of code and functions at a glance. Benchee is also versatile and extensible, relying only on functions - no macros!

Somewhat inspired by [benchmark-ips](https://github.com/evanphx/benchmark-ips) from the ruby world, but a very different interface and a functional spin.

General features:

* first runs the functions for a given warmup time without recording the results, to simulate a _"warm"_ running system
* plugin/extensible friendly architecture so you can use different formatters to generate CSV or whatever
* well tested
* well documented
* execute benchmark jobs in parallel to gather more results in the same time, or simulate a system under load
* nicely formatted console output
* provides you with **lots of statistics** - check the next list

Provides you with the following statistical data:

* **average**   - average execution time (the lower the better)
* **ips**       - iterations per second, how often can the given function be executed within one second (the higher the better)
* **deviation** - standard deviation (how much do the results vary), given as a percentage of the average (raw absolute values also available)
* **median**    - when all measured times are sorted, this is the middle value (or average of the two middle values when the number of samples is even). More stable than the average and somewhat more likely to be a typical value you see.

Benchee does not:

* Keep results of previous and compare them, if you want that have a look at [benchfella](https://github.com/alco/benchfella) or [bmark](https://github.com/joekain/bmark)

Benchee has no runtime dependencies and is aimed at being the core benchmarking logic. Further functionality is provided through plugins that then pull in dependencies, such as CSV export. Check out the [available plugins](#plugins)!

## Installation

When [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

Add benchee to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:benchee, "~> 0.2", only: :dev}]
end
```

Install via `mix deps.get` and then happy benchmarking as described in Usage :)

## Usage

After installing just write a little Elixir benchmarking script:

```elixir
list = Enum.to_list(1..10_000)
map_fun = fn(i) -> [i, i * i] end

Benchee.run(%{time: 3}, %{
  "flat_map"    => fn -> Enum.flat_map(list, map_fun) end,
  "map.flatten" => fn -> list |> Enum.map(map_fun) |> List.flatten end})
```

First configuration options are passed, the only options available so far are:

* `warmup` - the time in seconds for which a benchmark should be run without measuring times before real measurements start. This simulates a _"warm"_ running system. Defaults to 2.
* `time`   - the time in seconds for how long each individual benchmark should be run and measured. Defaults to 5.
* `parallel` - each job will be executed in `parallel` number processes. Gives you more data in the same time, but also puts a load on the system interfering with benchmark results. Defaults to 1.
* formatters - list of formatter function you'd like to run to output the benchmarking results of the suite when using `Benchee.run/2`. Functions need to accept one argument (which is the benchmarking suite with all data) and then use that to produce output. Used for plugins. Defaults to the builtin console formatter calling `Benche.Formatters.Console.output/1`.


Running this script produces an output like:

```
tobi@happy ~/github/benchee $ mix run samples/run.exs
Benchmark suite executing with the following configuration:
warmup: 2.0s
time: 3.0s
parallel: 1
Estimated total run time: 10.0s

Benchmarking flat_map...
Benchmarking map.flatten...

Name                  ips        average    deviation         median
map.flatten       1265.01       790.51μs    (±14.00%)       756.00μs
flat_map           861.26      1161.09μs     (±5.43%)      1191.00μs

Comparison:
map.flatten       1265.01
flat_map           861.26 - 1.47x slower

```

See the general description for the meaning of the different statistics.

It is important to note that the benchmarking code shown before is the convenience interface. The same benchmark in its more verbose form looks like this:

```elixir
list = Enum.to_list(1..10_000)
map_fun = fn(i) -> [i, i * i] end

Benchee.init(%{time: 3})
|> Benchee.benchmark("flat_map", fn -> Enum.flat_map(list, map_fun) end)
|> Benchee.benchmark("map.flatten",
                     fn -> list |> Enum.map(map_fun) |> List.flatten end)
|> Benchee.measure
|> Benchee.statistics
|> Benchee.Formatters.Console.output
```

This is a take on the _functional transformation_ of data applied to benchmarks here:

1. Configure the benchmarking suite to be run
2. run n benchmarks with the given configuration gathering raw run times per function (done in 2 steps, gathering the benchmarks and then running them with `Benchee.measure`)
3. Generate statistics based on the raw run times
4. Format the statistics in a suitable way
5. Output the formatted statistics

This is also part of the official API and allows for more fine grained control.
Do you just want to have all the raw run times? Grab them before `Benchee.statistics`! Just want to have the calculated statistics and use your own formatting? Grab the result of `Benchee.statistics`! Or, maybe you want to write to a file or send an HTTP post to some online service? Just replace the `IO.puts`.

This way Benchee should be flexible enough to suit your needs and be extended at will. Have a look at the [available plugins](#plugins).

For more example usages and benchmarks have a look at the [`samples`](https://github.com/PragTob/benchee/tree/master/samples) directory!

## Formatters

Among all the configuration options, one that you probably want to use are the formatters. Formatters are functions that take one argument (the benchmarking suite with all its results) and then generate some output. You can specify multiple formatters to run for the benchmarking run.

So if you are using the [CSV plugin](https://github.com/PragTob/benchee_csv) and you want to run both the console formatter and the CSV formatter this looks like this:

```elixir
list = Enum.to_list(1..10_000)
map_fun = fn(i) -> [i, i * i] end

Benchee.run(
  %{
    formatters: [
      &Benchee.Formatters.CSV.output/1,
      &Benchee.Formatters.Console.output/1
    ],
    csv: %{file: "my.csv"}
  },
  %{
    "flat_map"    => fn -> Enum.flat_map(list, map_fun) end,
    "map.flatten" => fn -> list |> Enum.map(map_fun) |> List.flatten end
  })
```

## Plugins

Packages that work with Benchee to provide additional functionality.

* [BencheeCSV](//github.com/PragTob/benchee_csv) - generate CSV from your Benchee benchmark results so you can import them into your favorite spreadsheet tool and make fancy graphs

(You didn't really expect to find tons of plugins here when the library was just released, did you? ;) )

## Contributing

Contributions to Benchee are very welcome! Bug reports, documentation, spelling corrections, whole features, feature ideas, bugfixes, new plugins, fancy graphics... all of those (and probably more) are much appreciated contributions!

You can get started with a look at the [open issues](https://github.com/PragTob/benchee/issues).

A couple of (hopefully) helpful points:

* Feel free to ask for help and guidance on an issue/PR ("How can I implement this?", "How could I test this?", ...)
* Feel free to open early/not yet complete pull requests to get some early feedback
* When in doubt if something is a good idea open an issue first to discuss it
* In case I don't respond feel free to bump the issue/PR or ping me on other places

## Development

* `mix deps.get` to install dependencies
* `mix test` to run tests or `mix test.watch` to run them continuously while you change files
* `mix credo` or `mix credo --strict` to find code style problems (not too strict with the 80 width limit for sample output in the docs)
