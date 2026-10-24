defmodule Benchee.EvaluationWarningTest do
  use ExUnit.Case, async: true

  describe "warn when functions are evaluated" do
    test "warns when run in iex" do
      # test env to avoid repeated compilation on CI
      port =
        Port.open({:spawn, "iex -S mix"}, [
          :binary,
          :exit_status,
          env: [{~c"MIX_ENV", ~c"test"}]
        ])

      try do
        # wait for startup
        # How the output is split up into messages is up to the OS/port, so sometimes the prompt is
        # its own message and sometimes it's attached to the previous output (like the startup
        # banner) - hence we gotta do our own `receive` checking instead of pattern matching on
        # a message.
        {:ok, _output} = wait_for_output(port, "iex(1)>")

        send(
          port,
          {self(),
           {:command, "Benchee.run(%{\"test\" => fn -> 1 end}, time: 0.001, warmup: 0)\n"}}
        )

        # waiting for the warning and also for iex to be ready for input again/the benchmark to be
        # finished again. As the output may be chunked arbitrarily, we look at all of it.
        {:ok, output} = wait_for_output(port, "iex(2)>")

        assert [_, message] = String.split(output, "Warning: ", parts: 2)
        assert message =~ ~r/test.+evaluated.+slower.+compiled.+module.+/is
      after
        stop_iex(port)
      end
    end

    # https://elixirforum.com/t/starting-shutting-down-iex-with-a-port-gracefully/60388/2?u=pragtob
    # describes ctrl+g q, but without a TTY that was not reliable and left an orphaned `iex`
    # (a whole VM!) behind on every test run. So we tell it to halt and make sure it's gone.
    defp stop_iex(port) do
      case Port.info(port, :os_pid) do
        {:os_pid, os_pid} ->
          send(port, {self(), {:command, "System.halt()\n"}})

          receive do
            {^port, {:exit_status, _}} -> :ok
          after
            5_000 -> kill_os_process(os_pid)
          end

        # already gone
        nil ->
          :ok
      end
    end

    defp kill_os_process(os_pid) do
      case :os.type() do
        {:win32, _} -> System.cmd("taskkill", ["/F", "/PID", Integer.to_string(os_pid)])
        _ -> System.cmd("kill", ["-9", Integer.to_string(os_pid)])
      end
    end

    # Collects all the output of the port until it contains `expected`, returns everything
    # received so far. Timeout is huge because of CI.
    defp wait_for_output(port, expected, received \\ "") do
      if String.contains?(received, expected) do
        {:ok, received}
      else
        receive do
          {^port, {:data, output}} ->
            wait_for_output(port, expected, received <> output)
        after
          20_000 ->
            raise RuntimeError,
                  "Waited too long for iex to send #{inspect(expected)}, got: #{inspect(received)}"
        end
      end
    end
  end
end
