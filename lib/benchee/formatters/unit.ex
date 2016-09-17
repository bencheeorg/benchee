defmodule Benchee.Unit do
  @moduledoc """
  Provides scaling and labeling functions for numbers. Use "count" functions
  for numbers that represent countable things, such as iterations per second.
  Use "duration" functions for numbers that represent durations, such as run
  times.
  """

  @type unit :: atom
  @type scaled_number :: {number, unit}

  # In 1.3, this could be declared as `keyword`, but use a custom type so it
  # will also compile in 1.2
  @type options ::[{atom, atom}]

  @doc """
  Scales a number in a domain's base unit to an equivalent value in the best
  fit unit. Results are a `{number, unit}` tuple. See `Benchee.Unit.Count` and
  `Benchee.Unit.Duration` for examples
  """
  @callback scale(number) :: scaled_number

  @callback format(number) :: String.t

  @callback best(list, options) :: unit

  @callback label(unit) :: String.t

  @callback magnitude(unit) :: number

  def float_precision(float) when float < 0.01, do: 5
  def float_precision(float) when float < 0.1, do: 4
  def float_precision(float) when float < 0.2, do: 3
  def float_precision(_float), do: 2

  # Common functions used by unit types
  defmodule Common do
    @moduledoc false

    def format({count, unit}, module) do
      "~.#{Benchee.Unit.float_precision(count)}f~ts"
      |> :io_lib.format([count, module.label(unit)])
      |> to_string
    end

    def format(number, module) do
      number
      |> module.scale
      |> format(module)
    end

    def magnitude(units, unit) do
      units
      |> Map.fetch!(unit)
      |> Map.fetch!(:magnitude)
    end

    def label(units, unit) do
      units
      |> Map.fetch!(unit)
      |> Map.fetch!(:short)
    end

    def best_unit(list, module, opts) do
      case Keyword.get(opts, :strategy, :best) do
        :best     -> best_unit(list, module)
        :largest  -> largest_unit(list, module)
        :smallest -> smallest_unit(list, module)
      end
    end

    # Finds the most common unit in the list. In case of tie, chooses the
    # largest of the most common
    defp best_unit(list, module) do
      list
      |> Enum.map(&(scale_unit(&1, module)))
      |> Enum.reduce(%{}, &totals_by_unit/2)
      |> Enum.into([])
      |> Enum.sort(&(sort_by_total_and_magnitude(&1, &2, module)))
      |> hd
      |> elem(0)
    end

    # Finds the smallest unit in the list
    defp smallest_unit(list, module) do
      list
      |> Enum.map(&(scale_unit(&1, module)))
      |> Enum.min_by(&module.magnitude/1)
    end

    # Finds the largest unit in the list
    defp largest_unit(list, module) do
      list
      |> Enum.map(&(scale_unit(&1, module)))
      |> Enum.max_by(&module.magnitude/1)
    end

    defp scale_unit(count, module) do
      {_, unit} = module.scale(count)
      unit
    end

    defp totals_by_unit(unit, acc) do
      count = Map.get(acc, unit, 0)
      Map.put(acc, unit, count + 1)
    end

    # Sorts two elements first by total, then by magnitude of the unit in case
    # of tie
    defp sort_by_total_and_magnitude({units_a, total}, {units_b, total}, module) do
      module.magnitude(units_a) > module.magnitude(units_b)
    end
    defp sort_by_total_and_magnitude({_, total_a}, {_, total_b}, _module) do
      total_a > total_b
    end
  end
end
