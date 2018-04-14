# Benchee [![Hex Version](https://img.shields.io/hexpm/v/benchee.svg)](https://hex.pm/packages/benchee) [![docs](https://img.shields.io/badge/docs-hexpm-blue.svg)](https://hexdocs.pm/benchee/) [![Build Status Travis/Linux](https://travis-ci.org/PragTob/benchee.svg?branch=master)](https://travis-ci.org/PragTob/benchee) [![Build status AppVeyor/Windows](https://ci.appveyor.com/api/projects/status/0b5nw0ar9s232oan/branch/master?svg=true)](https://ci.appveyor.com/project/PragTob/benchee/branch/master) [![Coverage Status](https://coveralls.io/repos/github/PragTob/benchee/badge.svg?branch=master)](https://coveralls.io/github/PragTob/benchee?branch=master) [![Inline docs](http://inch-ci.org/github/PragTob/benchee.svg)](http://inch-ci.org/github/PragTob/benchee)

Library for easy and nice (micro) benchmarking in Elixir. It allows you to compare the performance of different pieces of code at a glance. Benchee is also versatile and extensible, relying only on functions! There are also a bunch of [plugins](#plugins) to draw pretty graphs and more!

Benchee runs each of your functions for a given amount of time after an initial warmup, it then measures their run time and optionally memory consumption. It then shows different statistical values like average, iterations per second and the standard deviation.

Benchee has a nice and concise main interface, its behavior can be altered through lots of [configuration options](#configuration):

```elixir
list = Enum.to_list(1..10_000)
map_fun = fn(i) -> [i, i * i] end

Benchee.run(%{
  "flat_map"    => fn -> Enum.flat_map(list, map_fun) end,
  "map.flatten" => fn -> list |> Enum.map(map_fun) |> List.flatten end
}, time: 10, memory_time: 2)
```

Produces the following output on the console:

```
tobi@speedy:~/github/benchee(master)$ mix run samples/run.exs
Operating System: Linux"
CPU Information: Intel(R) Core(TM) i7-4790 CPU @ 3.60GHz
Number of Available Cores: 8
Available memory: 15.61 GB
Elixir 1.6.4
Erlang 20.3

Benchmark suite executing with the following configuration:
warmup: 2 s
time: 10 s
memory time: 2 s
parallel: 1
inputs: none specified
Estimated total run time: 28 s


Benchmarking flat_map...
Benchmarking map.flatten...

Name                  ips        average  deviation         median         99th %
flat_map           2.31 K      433.25 μs     ±8.64%         428 μs         729 μs
map.flatten        1.22 K      822.22 μs    ±16.43%         787 μs        1203 μs

Comparison:
flat_map           2.31 K
map.flatten        1.22 K - 1.90x slower

Memory usage statistics:

Name           Memory usage
flat_map          625.54 KB
map.flatten       781.85 KB - 1.25x memory usage

**All measurements for memory usage were the same**

```

The aforementioned [plugins](#plugins) like [benchee_html](https://github.com/PragTob/benchee_html) make it possible to generate nice looking [html reports](http://www.pragtob.info/benchee/flat_map.html), where individual graphs can also be exported as PNG images:

![report](http://www.pragtob.info/benchee/images/report.png)

## Features

* first runs the functions for a given warmup time without recording the results, to simulate a _"warm"_ running system
* [measures memory](measuring-memory-consumption)
* provides you with lots of statistics - check the next list
* plugin/extensible friendly architecture so you can use different formatters to generate [CSV, HTML and more](#plugins)
* nicely formatted console output with units scaled to appropriate units
* [hooks](#hooks-setup-teardown-etc) to execute something before/after a benchmark
* execute benchmark jobs in parallel to gather more results in the same time, or simulate a system under load
* well tested
* well documented

Provides you with the following **statistical data**:

* **average**   - average execution time (the lower the better)
* **ips**       - iterations per second, aka how often can the given function be executed within one second (the higher the better)
* **deviation** - standard deviation (how much do the results vary), given as a percentage of the average (raw absolute values also available)
* **median**    - when all measured times are sorted, this is the middle value (or average of the two middle values when the number of samples is even). More stable than the average and somewhat more likely to be a typical value you see. (the lower the better)
* **99th %**    - 99th percentile, 99% of all run times are less than this

In addition, you can optionally output an extended set of statistics:

* **minimum**     - the smallest (fastest) run time measured for the job
* **maximum**     - the biggest (slowest) run time measured for the job
* **sample size** - the number of run time measurements taken
* **mode**        - the run time(s) that occur the most. Often one value, but can be multiple values if they occur the same amount of times. If no value occurs at least twice, this value will be nil.

## Installation

Add benchee to your list of dependencies in `mix.exs`:

```elixir
defp deps do
  [{:benchee, "~> 0.11", only: :dev}]
end
```

Install via `mix deps.get` and then happy benchmarking as described in [Usage](#usage) :)

Elixir versions supported are 1.4+.

## Usage

After installing just write a little Elixir benchmarking script:

```elixir
list = Enum.to_list(1..10_000)
map_fun = fn(i) -> [i, i * i] end

Benchee.run(%{
  "flat_map"    => fn -> Enum.flat_map(list, map_fun) end,
  "map.flatten" => fn -> list |> Enum.map(map_fun) |> List.flatten end
})
```

(names can also be specified as `:atoms` if you want to)

This produces the following output:

```
tobi@speedy ~/github/benchee $ mix run samples/run.exs
Elixir 1.4.0
Erlang 19.1
Benchmark suite executing with the following configuration:
warmup: 2.0s
time: 5.0s
parallel: 1
inputs: none specified
Estimated total run time: 14.0s

Benchmarking flat_map...
Benchmarking map.flatten...

Name                  ips        average  deviation         median
flat_map           2.28 K      438.07 μs    ±16.66%         419 μs
map.flatten        1.25 K      802.99 μs    ±13.40%         782 μs

Comparison:
flat_map           2.28 K
map.flatten        1.25 K - 1.83x slower
```

See [Features](#features) for a description of the different statistical values and what they mean.

If you're looking to see how to make something specific work, please refer to the [samples](https://github.com/PragTob/benchee/tree/master/samples) directory. Also, especially when wanting to extend benchee check out the [hexdocs](https://hexdocs.pm/benchee/api-reference.html).

### Configuration

Benchee takes a wealth of configuration options, however those are entirely optional. Benchee ships with sensible defaults for all of these.

In the most common `Benchee.run/2` interface configuration options are passed as the second argument in the form of an optional keyword list:

```elixir
Benchee.run(%{"some function" => fn -> magic end}, print: [benchmarking: false])
```

The available options are the following (also documented in [hexdocs](https://hexdocs.pm/benchee/Benchee.Configuration.html#init/1)).

* `warmup` - the time in seconds for which a benchmarking job should be run without measuring times before "real" measurements start. This simulates a _"warm"_ running system. Defaults to 2.
* `time` - the time in seconds for how long each individual benchmarking job should be run for measuring the execution times (run time performance). Defaults to 5.
* `memory_time` - the time in seconds for how long [memory measurements](measuring-memory-consumption) should be conducted. Defaults to 0 (turned off).
* `inputs` - a map from descriptive input names to some different input, your benchmarking jobs will then be run with each of these inputs. For this to work your benchmarking function gets the current input passed in as an argument into the function. Defaults to `nil`, aka no input specified and functions are called without an argument. See [Inputs](#inputs).
* `formatters` - list of formatters either as module implementing the formatter behaviour or formatter functions. They are run when using `Benchee.run/2`. Functions need to accept one argument (which is the benchmarking suite with all data) and then use that to produce output. Used for plugins. Defaults to the builtin console formatter `Benchee.Formatters.Console`. See [Formatters](#formatters).
* `pre_check` - whether or not to run each job with each input - including all given before or after scenario or each hooks - before the benchmarks are measured to ensure that your code executes without error. This can save time while developing your suites. Defaults to `false`.
* `parallel` - the function of each benchmarking job will be executed in `parallel` number processes. If `parallel: 4` then 4 processes will be spawned that all execute the _same_ function for the given time. When these finish/the time is up 4 new processes will be spawned for the next job/function. This gives you more data in the same time, but also puts a load on the system interfering with benchmark results. For more on the pros and cons of parallel benchmarking [check the wiki](https://github.com/PragTob/benchee/wiki/Parallel-Benchmarking). Defaults to 1 (no parallel execution).
* `save` - specify a `path` where to store the results of the current benchmarking suite, tagged with the specified `tag`. See [Saving & Loading](#saving-loading-and-comparing-previous-runs).
* `load` - load saved suit or suits to compare your current benchmarks against. Can be a string or a list of strings or patterns. See [Saving & Loading](#saving-loading-and-comparing-previous-runs).
* `print` - a map from atoms to `true` or `false` to configure if the output identified by the atom will be printed during the standard Benchee benchmarking process. All options are enabled by default (true). Options are:
  * `:benchmarking`  - print when Benchee starts benchmarking a new job (Benchmarking name ..)
  * `:configuration` - a summary of configured benchmarking options including estimated total run time is printed before benchmarking starts
  * `:fast_warning` - warnings are displayed if functions are executed too fast leading to inaccurate measures
* `console` - options for the built-in console formatter:
  * `:comparison` - if the comparison of the different benchmarking jobs (x times slower than) is shown. Enabled by default.
  * `extended_statistics` - display more statistics, aka `minimum`, `maximum`, `sample_size` and `mode`. Disabled by default.
* `:unit_scaling` - the strategy for choosing a unit for durations and
  counts. May or may not be implemented by a given formatter (The console
  formatter implements it). When scaling a value, Benchee finds the "best fit"
  unit (the largest unit for which the result is at least 1). For example,
  1_200_000 scales to `1.2 M`, while `800_000` scales to `800 K`. The
  `unit_scaling` strategy determines how Benchee chooses the best fit unit for
  an entire list of values, when the individual values in the list may have
  different best fit units. There are four strategies, defaulting to `:best`:
    * `:best`     - the most frequent best fit unit will be used, a tie
    will result in the larger unit being selected.
    * `:largest`  - the largest best fit unit will be used (i.e. thousand
    and seconds if values are large enough).
    * `:smallest` - the smallest best fit unit will be used (i.e.
    millisecond and one)
    * `:none`     - no unit scaling will occur. Durations will be displayed
    in microseconds, and counts will be displayed in ones (this is
    equivalent to the behaviour Benchee had pre 0.5.0)
* `:before_scenario`/`after_scenario`/`before_each`/`after_each` - read up on them in the [hooks section](#hooks-setup-teardown-etc)

### Measuring memory consumption

Starting with version 0.13, users can now get measurements of how much memory their benchmarks use. This measurement is **not** the actual effect on the size of the BEAM VM size, but the total amount of memory that was allocated during the execution of a given scenario. This includes all memory that was garbage collected during the execution of that scenario. It **does not** include any memory used in any process other than the original one in which the scenario is run.

This measurement of memory does not affect the measurement of run times.

In cases where all measurements of memory consumption are identical, which happens very frequently, the full statistics will be omitted from the standard console formatter. If your function is deterministic, this will always be the case. Only in functions with some amount of randomness will there be variation in memory usage.

Memory measurement is disabled by default, and you can choose to enable it by passing `memory_time: your_seconds` option to `Benchee.run/2`:

```elixir
Benchee.run(%{
  "something_great" => fn -> cool_stuff end
}, memory_time: 2)
```

Memory time can be specified separately as it will often be constant - so it might not need as much measuring time.

A full example, including an example of the console output, can be found
[here](samples/measure_memory.exs).

### Inputs

`:inputs` is a very useful configuration that allows you to run the same benchmarking jobs with different inputs. You specify the inputs as a map from name (String or atom) to the actual input value. Functions can have different performance characteristics on differently shaped inputs - be that structure or input size.

One of such cases is comparing tail-recursive and body-recursive implementations of `map`. More information in the [repository with the benchmark](https://github.com/PragTob/elixir_playground/blob/master/bench/tco_blog_post_focussed_inputs.exs) and the [blog post](https://pragtob.wordpress.com/2016/06/16/tail-call-optimization-in-elixir-erlang-not-as-efficient-and-important-as-you-probably-think/).

```elixir
map_fun = fn(i) -> i + 1 end
inputs = %{
  "Small (1 Thousand)"    => Enum.to_list(1..1_000),
  "Middle (100 Thousand)" => Enum.to_list(1..100_000),
  "Big (10 Million)"      => Enum.to_list(1..10_000_000),
}

Benchee.run %{
  "map tail-recursive" =>
    fn(list) -> MyMap.map_tco(list, map_fun) end,
  "stdlib map" =>
    fn(list) -> Enum.map(list, map_fun) end,
  "map simple body-recursive" =>
    fn(list) -> MyMap.map_body(list, map_fun) end,
  "map tail-recursive different argument order" =>
    fn(list) -> MyMap.map_tco_arg_order(list, map_fun) end
}, time: 15, warmup: 5, inputs: inputs
```

This means each function will be benchmarked with each input that is specified in the inputs. Then you'll get the output divided by input so you can see which function is fastest for which input.

Therefore, I **highly recommend** using this feature and checking different realistically structured and sized inputs for the functions you benchmark!

### Formatters

Among all the configuration options, one that you probably want to use are the formatters. They format and print out the results of the benchmarking suite.

The `:formatters` option is specified a list of:
* modules implementing the `Benchee.Formatter` behaviour, or...
* functions that take one argument (the benchmarking suite with all its results) and then do whatever you want them to

So if you are using the [HTML plugin](https://github.com/PragTob/benchee_html) and you want to run both the console formatter and the HTML formatter this looks like this (after you installed it of course):

```elixir
list = Enum.to_list(1..10_000)
map_fun = fn(i) -> [i, i * i] end

Benchee.run(%{
  "flat_map"    => fn -> Enum.flat_map(list, map_fun) end,
  "map.flatten" => fn -> list |> Enum.map(map_fun) |> List.flatten end
},
  formatters: [
    Benchee.Formatters.HTML,
    Benchee.Formatters.Console
  ],
  formatter_options: [html: [file: "samples_output/my.html"]]
)
```

### Extended Console Formatter Statistics

Showing more statistics such as `minimum`, `maximum`, `sample_size` and `mode` is as simple as passing `extended_statistics: true` to the console formatter.

```elixir
list = Enum.to_list(1..10_000)
map_fun = fn(i) -> [i, i * i] end

Benchee.run(%{
  "flat_map"    => fn -> Enum.flat_map(list, map_fun) end,
  "map.flatten" => fn -> list |> Enum.map(map_fun) |> List.flatten end
}, time: 10, formatter_options: %{console: %{extended_statistics: true}})
```

Which produces:

```
# your normal output...

Extended statistics:
Name                minimum        maximum    sample size                     mode
flat_map             365 μs        1371 μs        22.88 K                   430 μs
map.flatten          514 μs        1926 μs        13.01 K                   517 μs
```

(Btw. notice how the modes of both are much closer and for `map.flatten` much less than the average of `766.99`, see `samples/run_extended_statistics`)

### Saving, loading and comparing previous runs

Benchee can store the results of previous runs in a file and then load them again to compare them. For example this is useful to compare what was recorded on the master branch against a branch with performance improvements.

**Saving** is done through the `save` configuration option. You can specify a `path` where results are saved, or you can use the default option of`"benchmark.benchee"` if you don't pass a `path`. You can also pass a `tag` option which annotates these results (for instance with a branch name). The default option for the `tag` is a timestamp of when the benchmark was run.

**Loading** is done through the `load` option specifying a path to the file to
load (for instance `benchmark.benchee`). You can also specify multiple files to load through a list of paths (`["my.benchee", "master_save.benchee"]`) - each one of those can also be a glob expression to match even more files glob (`"save_number*.benchee"`).

```elixir
Benchee.run(%{
  "something_great" => fn -> cool_stuff end
},
  save: [path: "save.benchee", tag: "first-try"]
)

Benchee.run(%{}, load: "save.benchee")
```

In the more verbose API this is triggered via `Benchee.load/1`.

### Hooks (Setup, Teardown etc.)

Most of the time, it's best to keep your benchmarks as simple as possible: plain old immutable functions work best. But sometimes you need other things to happen. When you want to add before or after hooks to your benchmarks, we've got you covered! Before you dig into this section, **you usually don't need hooks**.

Benchee has three types of hooks:

* [Suite hooks](#suite-hooks)
* [Scenario hooks](#scenario-hooks)
* [Benchmarking function hooks](#benchmarking-function-hooks)


Of course, **hooks are not included in the measured run times**. So they are there especially if you want to do something and want it to **not be included in the measured times**. Sadly there is the notable exception of _too_fast_functions_ (the ones that execute in less than 10 microseconds). As we need to measure their repeated invocations to get halfway good measurements `before_each` and `after_each` hooks are included there.

#### Suite hooks

It is very easy in benchee to do setup and teardown for the whole benchmarking suite (think: "before all" and "after all"). As benchee is just plain old functions, just do your setup and teardown before/after you call benchee:

```elixir
your_setup()

Benchee.run %{"Awesome stuff" => fn -> magic end }

your_teardown()
```

_When might this be useful?_

* Seeding the database with data to be used by all benchmarking functions
* Starting/shutting down a server, process, other dependencies

#### Scenario hooks

For the following discussions, it's important to know what benchee considers a "benchmarking scenario".

##### What is a scenario?

A scenario is the combination of one benchmarking function and one input. So, given this benchmark:

```elixir
Benchee.run %{
  "foo" => fn(input) -> ... end,
  "bar" => fn(input) -> ... end
}, inputs: %{
  "input 1" => 1,
  "input 2" => 2
}
```

there are 4 scenarios:

1. foo with input 1
2. foo with input 2
3. bar with input 1
4. bar with input 2

A scenario includes warmup and actual run time.

##### before_scenario

Is executed before every [scenario](#what-is-a-scenario) that it applies to (see [hook configuration](#hook-configuration-global-versus-local)). Before scenario hooks take the input of the scenario as an argument.

Since the return value of a `before_scenario` becomes the input for next steps (see [hook arguments and return values](#hook-arguments-and-return-values)),  there usually are 3 kinds of before scenarios:

* you just want to invoke a side effect: in that case return the given input unchanged
* you want to alter the given input: in that case alter the given input
* you want to keep the given input but add some other data: in that case return a tuple like `{original_input, new_fancy_data}`

For before scenario hooks, the _global_ hook is invoked first, then the _local_ (see [when does a hook happen?](#when-does-a-hook-happen-complete-example)).

Usage:

```elixir
Benchee.run %{
  "foo" =>
    {
      fn({input, resource}) -> foo(input, resource) end,
      before_scenario: fn({input, resource}) ->
        resource = alter_resource(resource)
        {input, resource}
      end
    },
  "bar" =>
    fn({input, resource}) -> bar(input, resource) end
}, inputs: %{"input 1" => 1},
   before_scenario: fn(input) ->
     resource = start_expensive_resource()
     {input, resource}
   end
```

_When might this be useful?_

* Starting a process to be used in your scenario
* Recording the PID of `self()` for use in your benchmark (each scenario is executed in its own process, so scenario PIDs aren't available in functions running before the suite)
* Clearing the cache before a scenario

##### after_scenario

Is executed after a scenario has completed. After scenario hooks receive the return value of the last `before_scenario` that ran as an argument. The return value is discarded (see [hook arguments and return values](#hook-arguments-and-return-values)).

For after scenario hooks, the _local_ hook is invoked first, then the _global_ (see [when does a hook happen?](#when-does-a-hook-happen-complete-example)).

Usage:

```elixir
Benchee.run %{
  "bar" => fn -> bar() end
}, after_scenario: fn(_input) -> bust_my_cache() end
```

_When might this be useful?_

* Busting caches after a scenario completed
* Deleting all the records in the database that the scenario just created
* Terminating whatever was setup by `before_scenario`

#### Benchmarking function hooks

You can also schedule hooks to run before and after each invocation of a benchmarking function.

##### before_each

Is executed before each invocation of the benchmarking function (before every measurement). Before each hooks receive the return value of their `before_scenario` hook as their argument. The return value of a before each hook becomes the input to the benchmarking function (see [hook arguments and return values](#hook-arguments-and-return-values)).

For before each hooks, the _global_ hook is invoked first, then the _local_ (see [when does a hook happen?](#when-does-a-hook-happen-complete-example)).

Usage:

```elixir
Benchee.run %{
  "bar" => fn(record) -> bar(record) end
}, inputs: %{ "record id" => 1},
   before_each: fn(input) -> get_from_db(input) end
```

_When might this be useful?_

* Retrieving a record from the database and passing it on to the benchmarking function to do something(tm) without the retrieval from the database adding to the benchmark measurement
* Busting caches so that all measurements are taken in an uncached state
* Picking a random value from a collection and passing it to the benchmarking function for measuring performance with a wider spread of values

##### after_each

Is executed directly after the invocation of the benchmarking function. After each hooks receive the return value of the benchmarking function as their argument. The return value is discarded (see [hook arguments and return values](#hook-arguments-and-return-values)).

For after each hooks, the _local_ hook is invoked first, then the _global_ (see [when does a hook happen?](#when-does-a-hook-happen-complete-example)).

Usage:

```elixir
Benchee.run %{
  "bar" => fn(input) -> bar(input) end
}, inputs: %{ "input 1" => 1}.
   after_each: fn(result) -> assert result == 42 end
```

_When might this be useful?_

* Running assertions that whatever your benchmarking function returns is truly what it should be (i.e. all "contestants" work as expected)
* Busting caches/terminating processes setup in `before_each` or elsewhere
* Deleting files created by the benchmarking function

#### Hook arguments and return values

Before hooks form a chain, where the return value of the previous hook becomes the argument for the next one. The first defined `before` hook receives the scenario input as an argument, and returns a value that becomes the argument of the next in the chain. The benchmarking function receives the value of the last `before` hook as its argument (or the scenario input if there are no `before` hooks).

After hooks do not form a chain, and their return values are discarded. An `after_each` hook receives the return value of the benchmarking function as its argument. An `after_scenario` function receives the return value of the last `before_scenario` that ran (or the scenario's input if there is no `before_scenario` hook).

If you haven't defined any inputs, the hook chain is started with the special input argument returned by `Benchee.Benchmark.no_input()`.

#### Hook configuration: global versus local

Hooks can be defined either _globally_ as part of the configuration or _locally_ for a specific benchmarking function. Global hooks will be executed for every scenario in the suite. Local hooks will only be executed for scenarios involving that benchmarking function.

**Global hooks**

Global hooks are specified as part of the general benchee configuration:

```elixir
Benchee.run %{
  "foo" => fn(input) -> ... end,
  "bar" => fn(input) -> ... end
}, inputs: %{
     "input 1" => 1,
     "input 2" => 2,
  },
  before_scenario: fn(input) -> ... end
```

Here the `before_scenario` function will be executed for all 4 scenarios present in this benchmarking suite.

**Local hooks**

Local hooks are defined alongside the benchmarking function. To define a local hook, pass a tuple in the initial map, instead of just a single function. The benchmarking function comes first, followed by a keyword list specifying the hooks to run:

```elixir
Benchee.run %{
  "foo" => {fn(input) -> ... end, before_scenario: fn(input) -> ... end},
  "bar" => fn(input) -> ... end
}, inputs: %{
  "input 1" => 1,
  "input 2" => 2
}
```

Here `before_scenario` is only run for the 2 scenarios associated with `"foo"`, i.e. foo with input 1 and foo with input 2. It is _not_ run for any `"bar"` benchmarks.


#### When does a hook happen? (Complete Example)

Yes the whole hooks system is quite a lot to take in. Here is an overview showing the order of hook execution, along with the argument each hook receives (see [hook arguments and return values](#hook-arguments-and-return-values)). The guiding principle whether _local_ or _global_ is run first is that _local_ always executes closer to the benchmarking function.

Given the following code:

```elixir

suite_set_up()

Benchee.run %{
  "foo" =>
    {
      fn(input) -> foo(input) end,
      before_scenario: fn(input) ->
        local_before_scenario(input)
        input + 1
      end,
      before_each: fn(input) ->
        local_before_each(input)
        input + 1
      end,
      after_each: fn(value) ->
        local_after_each(value)
      end,
      after_scenario: fn(input) ->
        local_after_scenario(input)
      end
    },
  "bar" =>
    fn(input) -> bar(input) end
}, inputs: %{"input 1" => 1},
   before_scenario: fn(input) ->
     global_before_scenario(input)
     input + 1
   end,
   before_each: fn(input) ->
     global_before_each(input)
     input + 1
   end,
   after_each: fn(value) ->
     global_after_each(value)
   end,
   after_scenario: fn(input) ->
     global_after_scenario(input)
   end

suite_tear_down()
```

Keeping in mind that the order of foo and bar could be different, here is how the hooks are called:

```
suite_set_up

# starting with the foo scenario
global_before_scenario(1)
local_before_scenario(2) # as before_scenario incremented it

global_before_each(3)
local_before_each(4)
foo(5) # let's say foo(5) returns 6
local_after_each(6)
global_after_each(6)

global_before_each(3)
local_before_each(4)
foo(5) # let's say foo(5) returns 6
local_after_each(6)
global_after_each(6)

# ... this block is repeated as many times as benchee has time

local_after_scenario(3)
global_after_scenario(3)

# now it's time for the bar scenario, it has no hooks specified for itself
# so only the global hooks are run

global_before_scenario(1)

global_before_each(2)
bar(3) # let's say foo(3) returns 4
global_after_each(4)

global_before_each(2)
bar(3) # let's say foo(3) returns 4
global_after_each(4)

# ... this block is repeated as many times as benchee has time

global_after_scenario(2)

suite_tear_down
```

### More verbose usage

It is important to note that the benchmarking code shown in the beginning is the convenience interface. The same benchmark in its more verbose form looks like this:

```elixir
list = Enum.to_list(1..10_000)
map_fun = fn(i) -> [i, i * i] end

Benchee.init(time: 3)
|> Benchee.system
|> Benchee.benchmark("flat_map", fn -> Enum.flat_map(list, map_fun) end)
|> Benchee.benchmark("map.flatten",
                     fn -> list |> Enum.map(map_fun) |> List.flatten end)
|> Benchee.measure
|> Benchee.statistics
|> Benchee.load # can be omitted when you don't want to/need to load scenarios
|> Benchee.Formatters.Console.output
```

This is a take on the _functional transformation_ of data applied to benchmarks:

1. Configure the benchmarking suite to be run
2. Gather System data
3. Define the functions to be benchmarked
4. Run benchmarks with the given configuration gathering raw run times per function
5. Generate statistics based on the raw run times
6. Format the statistics in a suitable way and print them out

This is also part of the **official API** and allows for more **fine grained control**. (It's also what benchee does internally when you use `Benchee.run/2`).

Do you just want to have all the raw run times? Just work with the result of `Benchee.measure/1`! Just want to have the calculated statistics and use your own formatting? Grab the result of `Benchee.statistics/1`! Or, maybe you want to write to a file or send an HTTP post to some online service? Just grab the complete suite after statistics were generated.

It also allows you to alter behaviour, normally `Benchee.load/1` is called right before the formatters so that neither the benchmarks are run again or statistics are computed again. However, you might want to run the benchmarks again or recompute the statistics. Then you can call `Benchee.load/1` right at the start.

This way Benchee should be flexible enough to suit your needs and be extended at will. Have a look at the [available plugins](#plugins).

### Usage from Erlang

Before you dig deep into this, it is inherently easier to setup a small elixir project, add a dependency to your erlang project and then run the benchmarks from elixir. The reason is easy - mix knows about rebar3 and knows how to work with it. The reverse isn't true so the road ahead is somewhat bumpy.

There is an [example project](https://github.com/PragTob/benchee_erlang_try) to check out.

You can use the [rebar3_elixir_compile](https://github.com/barrel-db/rebar3_elixir_compile) plugin. In your `rebar.config` you can do the following which should get you started:

```erlang
deps, [
  {benchee, {elixir, "benchee", "0.9.0"}}
]}.

{plugins, [
    { rebar3_elixir_compile, ".*", {git, "https://github.com/barrel-db/rebar3_elixir_compile.git", {branch, "master"}}}
]}.

{provider_hooks, [
  {pre, [{compile, {ex, compile}}]},
  {pre, [{release, {ex, compile}}]}
]}.

{elixir_opts,
  [
    {env, dev}
  ]
}.
```

Then benchee already provides a `:benchee` interface for erlang compatibility which you can use. Sadly couldn't get it to work in an escript yet.

You can then invoke it like this (for instance):

```
tobi@comfy ~/github/benchee_erlang_try $ rebar3 shell
===> dependencies etc.
Erlang/OTP 18 [erts-7.3] [source] [64-bit] [smp:4:4] [async-threads:0] [hipe] [kernel-poll:false]

Eshell V7.3  (abort with ^G)
1> benchee:run(#{myFunc => fun() -> lists:sort([8, 2, 3, 4, 2, 1, 3, 4, 9, 10, 11, 12, 13, 20, 1000, -4, -5]) end}, [{warmup, 0}, {time, 2}]).
Operating System: Linux
CPU Information: Intel(R) Core(TM) i5-7200U CPU @ 2.50GHz
Number of Available Cores: 4
Available memory: 8.05 GB
Elixir 1.3.4
Erlang 18.3
Benchmark suite executing with the following configuration:
warmup: 0.0 μs
time: 2 s
parallel: 1
inputs: none specified
Estimated total run time: 2 s


Benchmarking myFunc...

Name             ips        average  deviation         median
myFunc      289.71 K        3.45 μs   ±250.31%           3 μs
```

This doesn't seem to be too reliable right now, so suggestions and input are very welcome :)

## Plugins

Benchee only has small runtime dependencies that were initially extracted from it. Further functionality is provided through plugins that then pull in dependencies, such as HTML generation and CSV export. They help provide excellent visualization or interoperability.

* [benchee_html](//github.com/PragTob/benchee_html) - generate HTML including a data table and many different graphs with the possibility to export individual graphs as PNG :)
* [benchee_csv](//github.com/PragTob/benchee_csv) - generate CSV from your Benchee benchmark results so you can import them into your favorite spreadsheet tool and make fancy graphs
* [benchee_json](//github.com/PragTob/benchee_json) - export suite results as JSON to feed anywhere or feed it to your JavaScript and make magic happen :)

With the HTML plugin for instance you can get fancy graphs like this boxplot:

![boxplot](http://www.pragtob.info/benchee/images/boxplot.png)

Of course there also are normal bar charts including standard deviation:

![flat_map_ips](http://www.pragtob.info/benchee/images/flat_map_ips.png)

## Presentation + general benchmarking advice

If you're into watching videos of conference talks and also want to learn more about benchmarking in general I can recommend watching my talk from [ElixirLive 2016](http://www.elixirlive.com/). [Slides can be found here](https://pragtob.wordpress.com/2016/12/03/slides-how-fast-is-it-really-benchmarking-in-elixir/), video - click the washed out image below ;)

[![Benchee Video](http://www.pragtob.info/images/elixir_live_slide.png)](https://www.youtube.com/watch?v=7-mE5CKXjkw)

## Contributing [![Open Source Helpers](https://www.codetriage.com/pragtob/benchee/badges/users.svg)](https://www.codetriage.com/pragtob/benchee)

Contributions to benchee are **very welcome**! Bug reports, documentation, spelling corrections, whole features, feature ideas, bugfixes, new plugins, fancy graphics... all of those (and probably more) are much appreciated contributions!

Keep in mind that the [plugins](#plugins) live in their own repositories with their own issue tracker and they also like to get contributions :)

Please respect the [Code of Conduct](//github.com/PragTob/benchee/blob/master/CODE_OF_CONDUCT.md).

In addition to contributing code, you can help to triage issues. This can include reproducing bug reports, or asking for vital information such as version numbers or reproduction instructions. If you would like to start triaging issues, one easy way to get started is to [subscribe to pragtob/benchee on CodeTriage](https://www.codetriage.com/pragtob/benchee).

You can also look directly at the [open issues](https://github.com/PragTob/benchee/issues). There are `help wanted` and `good first issue` labels - those are meant as guidance, of course other issues can be tackled :)

A couple of (hopefully) helpful points:

* Feel free to ask for help and guidance on an issue/PR ("How can I implement this?", "How could I test this?", ...)
* Feel free to open early/not yet complete pull requests to get some early feedback
* When in doubt if something is a good idea open an issue first to discuss it
* In case I don't respond feel free to bump the issue/PR or ping me in other places

If you're on the [elixir-lang slack](https://elixir-lang.slack.com) also feel free to drop by in `#benchee` and say hi!

## Development

* `mix deps.get` to install dependencies
* `mix test` to run tests
* `mix dialyzer` to run dialyzer for type checking, might take a while on the first invocation (try building plts first with `mix dialyzer --plt`)
* `mix credo --strict` to find code style problems
* or run `mix guard` to run all of them continuously on file change
