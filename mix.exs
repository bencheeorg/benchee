defmodule Benchee.Mixfile do
  use Mix.Project

  @version "0.3.0"

  def project do
    [
      app: :benchee,
      version: @version,
      elixir: "~> 1.2",
      elixirc_paths: elixirc_paths(Mix.env),
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      deps: deps,
      docs: [source_ref: @version],
      package: package,
      name: "Benchee",
      source_url: "https://github.com/PragTob/benchee",
      description: """
      Versatile (micro) benchmarking that is extensible. Get statistics such as:
      average, iterations per second, standard deviation and the median.
      """
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_),     do: ["lib"]

  def application do
    [applications: [:logger]]
  end

  defp deps do
    [
      {:mix_test_watch, "~> 0.2",  only: :dev},
      {:credo,          "~> 0.4",  only: :dev},
      {:ex_doc,         "~> 0.11", only: :dev},
      {:earmark,        "~> 0.2",  only: :dev},
      {:inch_ex,        "~> 0.5",  only: :docs}
    ]
  end

  defp package do
    [
      maintainers: ["Tobias Pfeiffer"],
      licenses: ["MIT"],
      links: %{github: "https://github.com/PragTob/benchee"}
    ]
  end
end
