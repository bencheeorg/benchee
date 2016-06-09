defmodule Benchee.Mixfile do
  use Mix.Project

  def project do
    [
      app: :benchee,
      version: "0.1.0",
      elixir: "~> 1.2",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      deps: deps,
      package: package,
      name: "Benchee",
      source_url: "https://github.com/PragTob/benchee",
      description: """
      Versatile (micro) benchmarking that is extensible. Get statistics such as:
      average, iterations per second, standard deviation and the median.
      """
    ]
  end

  def application do
    [applications: [:logger]]
  end

  defp deps do
    [
      {:mix_test_watch, "~> 0.2",  only: :dev},
      {:credo,          "~> 0.4",  only: :dev},
      {:ex_doc,         "~> 0.11", only: :dev},
      {:earmark,        "~> 0.2",  only: :dev}
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
