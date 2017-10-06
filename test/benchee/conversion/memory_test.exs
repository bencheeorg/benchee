defmodule Benchee.Conversion.MemoryTest do
  use ExUnit.Case, async: true
  import Benchee.Conversion.Memory
  doctest Benchee.Conversion.Memory

  describe ".format" do
    test ".format(1_023)" do
    assert format(1_023) == "1023 B"
    end

    test ".format(1025)" do
      assert format(1_025) == "1.00 KB"
    end

    test ".format(876_543_219.8765)" do
      assert format(876_543_219.8765) == "835.94 MB"
    end

    test ".format(9_876_543_219.8765)" do
      assert format(9_876_543_219.8765) == "9.20 GB"
    end

    test ".format(14_569_876_543_219.8765)" do
      assert format(14_569_876_543_219.8765) == "13.25 TB"
    end

    test ".format(523.0)" do
      assert format(523.0) == "523 B"
    end

    test ".format(0)" do
      assert format(0) == "0 B"
    end
  end

  @list_with_mostly_megabytes [1, 200, 3_000_000, 4_000_000, 50_000_000, 50_000_000, 77_000_000_000]

  describe ".best" do
    test "when list is mostly megabytes" do
      assert best(@list_with_mostly_megabytes) == unit_for(:megabyte)
    end

    test "when list is mostly megabytes, strategy: :smallest" do
      assert best(@list_with_mostly_megabytes, strategy: :smallest) == unit_for(:byte)
    end

    test "when list is mostly megabytes, strategy: :largest" do
      assert best(@list_with_mostly_megabytes, strategy: :largest) == unit_for(:gigabyte)
    end

    test "when list is mostly megabytes, strategy: :none" do
      assert best(@list_with_mostly_megabytes, strategy: :none) == unit_for(:byte)
    end
  end
end