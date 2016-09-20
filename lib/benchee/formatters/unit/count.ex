defmodule Benchee.Unit.Count do
  alias Benchee.Unit.Common

  @moduledoc """
  Unit scaling for counts, such that 1000000 can be converted to 1 Million.
  """

  @behaviour Benchee.Unit

  @one_billion 1_000_000_000
  @one_million 1_000_000
  @one_thousand 1_000

  @units %{
    billion:  %{magnitude: @one_billion, short: "B", long: "Billion"},
    million:  %{magnitude: @one_million, short: "M", long: "Million"},
    thousand: %{magnitude: @one_thousand, short: "K", long: "Thousand"},
    one:      %{magnitude: 1, short: "", long: ""},
  }

  @doc """
  Scales a value representing a count in ones into a larger unit if appropriate

  ## Examples

      iex> Benchee.Unit.Count.scale(4_321.09)
      {4.32109, :thousand}

      iex> Benchee.Unit.Count.scale(0.0045)
      {0.0045, :one}

  """
  def scale(count) when count >= @one_billion do
    scale(count, :billion)
  end
  def scale(count) when count >= @one_million do
    scale(count, :million)
  end
  def scale(count) when count >= @one_thousand do
    scale(count, :thousand)
  end
  def scale(count) do
    scale(count, :one)
  end

  @doc """
  Scales a value representing a count in ones into a specified unit

  ## Examples

    iex> Benchee.Unit.Count.scale(12345, :one)
    {12345, :one}

    iex> Benchee.Unit.Count.scale(12345, :thousand)
    {12.345, :thousand}

    iex> Benchee.Unit.Count.scale(12345, :billion)
    {1.2345e-5, :billion}

    iex> Benchee.Unit.Count.scale(12345, :million)
    {0.012345, :million}

  """
  def scale(count, :billion) do
    {count / @one_billion, :billion}
  end
  def scale(count, :million) do
    {count / @one_million, :million}
  end
  def scale(count, :thousand) do
    {count / @one_thousand, :thousand}
  end
  def scale(count, :one) do
    {count, :one}
  end

  def format(count) do
    Common.format(count, __MODULE__)
  end

  def best(list, opts \\ [strategy: :best])
  def best(list, opts) do
    Common.best_unit(list, __MODULE__, opts)
  end

  def magnitude(unit) do
    Common.magnitude(@units, unit)
  end

  def label(unit) do
    Common.label(@units, unit)
  end

  def separator, do: " "
end
