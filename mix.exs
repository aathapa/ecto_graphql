defmodule GqlGen.MixProject do
  use Mix.Project

  def project do
    [
      app: :gql_gen,
      version: "0.1.0",
      elixir: "~> 1.19",
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      deps: deps(),
      name: "GqlGen",
      source_url: "https://github.com/aathapa/gql_gen"
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc, "~> 0.31", only: :dev, runtime: false}
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end

  defp description do
    "A generic GraphQL generator for Phoenix applications using Absinthe."
  end

  defp package do
    [
      name: "gql_gen",
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/aathapa/gql_gen"}
    ]
  end
end
