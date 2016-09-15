defmodule Benchee.Units do
  @one_billion 1_000_000_000
  @one_million 1_000_000
  @one_thousand 1_000

  def scale_count(count) when count >= @one_billion,  do: {count / @one_billion, :billion}
  def scale_count(count) when count >= @one_million,  do: {count / @one_million, :million}
  def scale_count(count) when count >= @one_thousand, do: {count / @one_thousand, :thousand}
  def scale_count(count), do: {count, :one}
end
