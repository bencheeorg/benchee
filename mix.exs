defmodule Benchee.Mixfile do
  use Mix.Project

  @version "0.11.0"

  def project do
    [
      app: :benchee,
      version: @version,
      elixir: "~> 1.3",
      elixirc_paths: elixirc_paths(Mix.env),
      consolidate_protocols: true,
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      deps: deps(),
      docs: [
        source_ref: @version,
        extras: ["README.md"],
        main: "readme"
      ],
      package: package(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        "coveralls": :test, "coveralls.detail": :test,
        "coveralls.post": :test, "coveralls.html": :test,
        "coveralls.travis": :test, "safe_coveralls.travis": :test],
      dialyzer: [
        flags:
          [:unmatched_returns, :error_handling, :race_conditions, :underspecs]
      ],
      name: "Benchee",
      source_url: "https://github.com/PragTob/benchee",
      description: """
      Versatile (micro) benchmarking that is extensible. Get statistics such as:
      average, iterations per second, standard deviation and the median.
      """
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support", "mix"]
  defp elixirc_paths(_),     do: ["lib"]

  def application do
    [applications: [:logger, :deep_merge]]
  end

  defp deps do
    [
      {:deep_merge,     "~> 0.1"},
      {:mix_test_watch, "~> 0.2",   only: :dev},
      {:credo,          "~> 0.4",   only: :dev},
      {:ex_doc,         "~> 0.11",  only: :dev},
      {:earmark,        "~> 1.0",   only: :dev},
      {:excoveralls,    "~> 0.7",   only: :test},
      {:inch_ex,        "~> 0.5",   only: :docs},
      {:dialyxir,       "~> 0.5",   only: :dev, runtime: false}
    ]
  end

  defp package do
    [
      maintainers: ["Tobias Pfeiffer"],
      licenses: ["MIT"],
      links: %{
        "github"     => "https://github.com/PragTob/benchee",
        "Blog posts" => "https://pragtob.wordpress.com/tag/benchee/"
      }
    ]
  end
end
