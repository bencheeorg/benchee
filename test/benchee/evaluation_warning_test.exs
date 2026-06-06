defmodule Benchee.EvaluationWarningTest do
  use ExUnit.Case, async: true

  describe "warn when functions are evaluated" do
    test "warns when run in iex" do
      # test env to avoid repeated compilation on CI
      port = Port.open({:spawn, "iex -S mix"}, [:binary, env: [{~c"MIX_ENV", ~c"test"}]])

      try do
        # wait for startup
        # timeout huge because of CI
        assert_receive {^port, {:data, "iex(1)> "}}, 20_000

        send(
          port,
          {self(),
           {:command, "Benchee.run(%{\"test\" => fn -> 1 end}, time: 0.001, warmup: 0)\n"}}
        )

        assert_receive {^port, {:data, "Warning: " <> message}}, 20_000
        assert message =~ ~r/test.+evaluated.+slower.+compiled.+module.+/is

        # waiting for iex to be ready for input again/the benchmark to be finished
        # sometimes we get "iex(2)>" as a separate message, sometimes it's attached to the
        # previous output - hence we gotta doe out own `receive` checking.
        assert :ok = wait_for_benchmark_finished(port)
      after
        # https://elixirforum.com/t/starting-shutting-down-iex-with-a-port-gracefully/60388/2?u=pragtob
        send(port, {self(), {:command, "\a"}})
        send(port, {self(), {:command, "q\n"}})
      end
    end

    defp wait_for_benchmark_finished(port) do
      receive do
        {^port, {:data, output}} ->
          if String.contains?(output, "iex(2)>") do
            :ok
          else
            wait_for_benchmark_finished(port)
          end
      after
        20_000 -> raise RuntimeError, "Waited too long for iex benchmark to finish/send iex(2)>"
      end
    end
  end
end
