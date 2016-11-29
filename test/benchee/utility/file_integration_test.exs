defmodule Benchee.Utility.FileIntegrationTest do
  use ExUnit.Case
  import Benchee.Utility.FileCreation
  import ExUnit.CaptureIO

  @directory "testing/files"
  @filename "#{@directory}/test.txt"
  @file_name_1 "#{@directory}/test_small_input.txt"
  @file_name_2 "#{@directory}/test_big_list.txt"
  @input_to_contents %{
    "small input" => "abc",
    "Big list"    => "ABC"
  }
  test ".each writes file contents just fine" do
    try do
      each(@input_to_contents, @filename, fn(file, content, _) ->
        :ok = IO.write file, content
      end)
      assert_correct_files()
    after
      File.rm_rf! @directory
    end
  end

  test ".each by default writes writes files" do
    try do
      capture_io fn -> each @input_to_contents, @filename end
      assert_correct_files()
    after
      File.rm_rf! @directory
    end
  end

  test ".each by default prints out filenames" do
    try do
      output = capture_io fn -> each @input_to_contents, @filename end

      assert output =~ @file_name_1
      assert output =~ @file_name_2
    after
      File.rm_rf! @directory
    end
  end

  defp assert_correct_files do
    assert File.exists? @file_name_1
    assert File.exists? @file_name_2

    assert File.read!(@file_name_1) == "abc"
    assert File.read!(@file_name_2) == "ABC"
  end

  test ".each is passed the filenames" do
    try do
      {:ok, agent} = Agent.start fn -> [] end
      each(@input_to_contents, @filename, fn(file, content, filename) ->
        :ok = IO.write file, content
        Agent.update agent, fn(state) -> [filename | state] end
      end)

      file_names = Agent.get agent, fn(state) -> state end
      assert Enum.member?(file_names, @file_name_1)
      assert Enum.member?(file_names, @file_name_2)
    after
      File.rm_rf! @directory
    end
  end
end
