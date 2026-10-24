defmodule Benchee.Mixfile do
  use Mix.Project

  @source_url "https://github.com/bencheeorg/benchee"
  @version "1.5.1"

  def project do
    [
      app: :benchee,
      version: @version,
      elixir: "~> 1.6",
      elixirc_paths: elixirc_paths(Mix.env()),
      consolidate_protocols: true,
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      docs: docs(),
      package: package(),
      test_coverage: [tool: ExCoveralls],
      test_ignore_filters: [~r/test\/fixtures/],
      dialyzer: [
        flags: [:underspecs],
        plt_file: {:no_warn, "tools/plts/benchee.plt"},
        plt_add_apps: [:table, :ex_unit]
      ],
      name: "Benchee",
      description: """
      Versatile (micro) benchmarking that is extensible. Get statistics such as:
      average, iterations per second, standard deviation and the median.
      """
    ]
  end

  def cli do
    [
      preferred_envs: [
        check: :test,
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test,
        "coveralls.travis": :test,
        "safe_coveralls.travis": :test
      ]
    ]
  end

  # Mirrors what CI runs on the "lint"/"type_check" job (see .github/workflows/main.yml).
  #
  # Runs in the test env (see `cli/0`) as that's where credo, dialyxir and the tests all live.
  defp aliases do
    [
      check: [
        "format --check-formatted",
        "credo",
        "test --warnings-as-errors",
        "dialyzer"
      ]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support", "mix"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    deps = [
      {:deep_merge, "~> 1.0"},
      {:statistex, "~> 1.1"},
      {:ex_guard, "~> 1.3", only: :dev},
      {:credo, "~> 1.7.13", only: lint_envs(), runtime: false},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:excoveralls, "~> 0.13", only: :test},
      {:dialyxir, "~> 1.0", only: lint_envs(), runtime: false},
      {:doctest_formatter, "~> 0.2", only: lint_envs(), runtime: false}
    ]

    # table relies on __STACKTRACE__ which was introduced in 1.7, we still support ~>1.6 though
    # as it's optional, this does not affect the function of Benchee
    if Version.compare(System.version(), "1.7.0") == :gt do
      [{:table, "~> 0.1.0", optional: true} | deps]
    else
      deps
    end
  end

  # credo & dialyxir are also available in :test so linting, type checking and testing can share
  # one `_build`. Older elixir versions (which only run the tests) can't compile credo though.
  defp lint_envs do
    if Version.match?(System.version(), ">= 1.15.0"), do: [:dev, :test], else: :dev
  end

  defp package do
    [
      maintainers: ["Tobias Pfeiffer", "Devon Estes"],
      licenses: ["MIT"],
      links: %{
        "Changelog" => "https://hexdocs.pm/benchee/changelog.html",
        "GitHub" => @source_url,
        "Blog posts" => "https://pragtob.wordpress.com/tag/benchee/"
      }
    ]
  end

  defp docs do
    [
      extras: [
        "CHANGELOG.md": [],
        "LICENSE.md": [title: "License"],
        "README.md": [title: "Readme"]
      ],
      main: "readme",
      source_url: @source_url,
      source_ref: @version,
      api_reference: false,
      skip_undefined_reference_warnings_on: ["CHANGELOG.md"]
    ]
  end
end
