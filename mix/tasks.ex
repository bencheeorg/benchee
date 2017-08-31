defmodule Mix.Tasks.SafeCoveralls.Travis do
  @moduledoc """
  Provides an entry point for travis's script that's safe from upload
  errors.
  """
  use Mix.Task

  @preferred_cli_env :test
  @shortdoc "A safe variant that doesn't crash on failed upload."

  def run(args) do
    try do
      Mix.Tasks.Coveralls.do_run(args, [type: "travis"])
    rescue
      ExCoveralls.ReportUploadError -> IO.puts "Upload to coveralls failed."
    end
  end
end
