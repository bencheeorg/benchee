# Benchee [![Build Status](https://travis-ci.org/PragTob/benchee.svg?branch=travis)](https://travis-ci.org/PragTob/benchee)

Library for easy and nice (micro) benchmarking. Somewhat inspired by [benchmark-ips](https://github.com/evanphx/benchmark-ips) from the ruby world, but of course it is a more functional spin.

It allows you to easily compare the performance of different pieces of code/functions.

Provides you with:

* average execution time (the lower the better)
* iterations per second (the higher the better)
* standard deviation (how much do the results vary)

Benchee does not:

* Keep results of previous and compare them, if you want that have a look at [benchfella](https://github.com/alco/benchfella) or [bmark](https://github.com/joekain/bmark)

## Usage

After installing just write a little benchmarking script:

    Benchee.init
    |> Benchee.benchmark("map", fn -> Enum.map(1..1_000, fn(i) -> i + 1 end) end)
    |> Benchee.report
    |> IO.puts


## Installation

When [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

Add benchee to your list of dependencies in `mix.exs`:

    def deps do
      [{:benchee, "~> 0.1.0", only: :dev}]
    end

Install via `mix deps.get` and then happy benchmarking :)
