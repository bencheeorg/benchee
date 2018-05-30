defmodule Benchee.Utility.FileCreationIntegrationTest do
  use ExUnit.Case
  import Benchee.Utility.FileCreation
  import ExUnit.CaptureIO

  @directory "testing/files"
  @filename "#{@directory}/test.txt"
  @file_name_1 "#{@directory}/test_small_input.txt"
  @file_name_2 "#{@directory}/test_big_list.txt"
  @input_to_contents %{
    "small input" => "abc",
    "Big list" => "ABC"
  }

  describe ".each" do
    test "writes file contents just fine" do
      try do
        each(@input_to_contents, @filename, fn file, content, _ ->
          :ok = IO.write(file, content)
        end)

        assert_correct_files()
      after
        File.rm_rf!(@directory)
        File.rm_rf!("testing")
      end
    end

    test "by default writes files" do
      try do
        capture_io(fn -> each(@input_to_contents, @filename) end)
        assert_correct_files()
      after
        File.rm_rf!(@directory)
        File.rm_rf!("testing")
      end
    end

    test "by default prints out filenames" do
      try do
        output = capture_io(fn -> each(@input_to_contents, @filename) end)

        assert output =~ @file_name_1
        assert output =~ @file_name_2
      after
        File.rm_rf!(@directory)
        File.rm_rf!("testing")
      end
    end

    test "with String.length/1 as a name it writes the correct file" do
      to_contents = %{
        "String.length/1" => "abc"
      }

      capture_io(fn -> each(to_contents, @filename) end)
      assert File.exists?("#{@directory}/test_string_length_1.txt")
    after
      File.rm_rf!(@directory)
      File.rm_rf!("testing")
    end

    defp assert_correct_files do
      assert File.exists?(@file_name_1)
      assert File.exists?(@file_name_2)
      refute File.exists?("#{@directory}/test")

      assert File.read!(@file_name_1) == "abc"
      assert File.read!(@file_name_2) == "ABC"
    end

    test "is passed the filenames" do
      try do
        {:ok, agent} = Agent.start(fn -> [] end)

        each(@input_to_contents, @filename, fn file, content, filename ->
          :ok = IO.write(file, content)
          Agent.update(agent, fn state -> [filename | state] end)
        end)

        file_names = Agent.get(agent, fn state -> state end)
        assert Enum.member?(file_names, @file_name_1)
        assert Enum.member?(file_names, @file_name_2)
      after
        File.rm_rf!(@directory)
        File.rm_rf!("testing")
      end
    end
  end
end
