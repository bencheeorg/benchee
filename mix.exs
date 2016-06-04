defmodule Benchee.Mixfile do
  use Mix.Project

  def project do
    [app: :benchee,
     version: "0.0.1",
     elixir: "~> 1.2",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps,
     package: package,
     name: "Benchee"
   ]
  end

  def application do
    [applications: [:logger]]
  end

  defp deps do
    [
      {:mix_test_watch, "~> 0.2",      only: :dev},
      {:credo,          "~> 0.4-beta", only: :dev},
      {:ex_doc,         "~> 0.11",     only: :dev},
      {:earmark,        "~> 0.2",       only: :dev}
    ]
  end

  defp package do
    [licenses: ["MIT"]]
  end
end
