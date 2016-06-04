# Benchee [![Build Status](https://travis-ci.org/PragTob/benchee.svg?branch=travis)](https://travis-ci.org/PragTob/benchee)

Library for easy and nice (micro) benchmarking. Somewhat inspired by [benchmark-ips](https://github.com/evanphx/benchmark-ips) from the ruby world, but of course it is a more functional spin.

It allows you to easily compare the performance of different pieces of code/functions.

Provides you with:

* average   - average execution time (the lower the better)
* ips       - iterations per second (the higher the better)
* deviation - standard deviation (how much do the results vary), given as a percentage of the average

Benchee does not:

* Keep results of previous and compare them, if you want that have a look at [benchfella](https://github.com/alco/benchfella) or [bmark](https://github.com/joekain/bmark)

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

Name                          ips            average        deviation
map.flatten                   1291.71        774.17μs       (±16.24%)
flat_map                      840.80         1189.34μs      (±5.44%)
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

This is also part of the official API and allows a more fine grained control.
Do you just want to have all the raw run times? Grab them before `Benchee.statistics`! Just want to have the calculated statistics and use your own formatting? Grab the result of `Benchee.statistics`! Or, maybe you want to write to a file or send an HTTP post to some online service? Just replace the `IO.puts`.

This way Benchee should be flexible enough to suit your needs and be extended at will.

## Installation

When [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

Add benchee to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:benchee, "~> 0.1.0", only: :dev}]
end
```

Install via `mix deps.get` and then happy benchmarking :)

## Development

* `mix deps.get` to install dependencies
* `mix test` to run tests or `mix test.watch` to run them continuously
* `mix credo` or `mix credo --strict` to find code style problems

Happy to review and accept pull requests or issues :)
