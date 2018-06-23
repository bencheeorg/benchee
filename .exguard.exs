use ExGuard.Config

project_files = ~r{\.(erl|ex|exs|eex|xrl|yrl)\z}i
deps = ~r{deps}

guard("credo", run_on_start: true)
|> command("mix credo --strict")
|> watch(project_files)
|> ignore(deps)
|> notification(:auto)

guard("mix format", run_on_start: true)
|> command("mix format --check-formatted")
|> watch(project_files)
|> ignore(deps)
|> notification(:auto)

guard("dialyzer", run_on_start: true)
|> command("mix dialyzer --halt-exit-status")
|> watch(project_files)
|> ignore(deps)
|> notification(:auto)

guard("test", run_on_start: true)
|> command("mix test --color")
|> watch(project_files)
|> ignore(deps)
|> notification(:auto)
