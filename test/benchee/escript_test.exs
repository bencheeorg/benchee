defmodule Benchee.EscriptTest do
  use ExUnit.Case, async: false

  import Benchee.IntegrationHelpers

  describe "escript building" do
    @working_directory File.cwd!()
    @sample_project_directory Path.expand("../fixtures/escript", __DIR__)
    test "benchee can be built into and used as an escript" do
      File.cd!(@sample_project_directory)
      # we don't match the exit_status right now to get better error messages potentially
      {output, exit_status} = System.cmd("bash", ["test.sh"])

      readme_sample_asserts(output)
      assert exit_status == 0
    after
      File.cd!(@working_directory)
    end
  end
end
