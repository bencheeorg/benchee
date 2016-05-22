# Benchee [![Build Status](https://travis-ci.org/PragTob/benchee.svg?branch=travis)](https://travis-ci.org/PragTob/benchee)

Library for easy and nice benchmarking. Somewhat inspired by [benchmark-ips](https://github.com/evanphx/benchmark-ips) from the ruby world, but of course it is a more functional spin.

Provides you with:

* average execution time (the lower the better)
* iterations per second (the higher the better)
* standard deviation (how much do the results vary)

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
