defmodule EctoGraphql.MixProject do
  use Mix.Project

  @github_url "https://github.com/aathapa/ecto_graphql"
  @version "0.2.0"

  def project do
    [
      app: :ecto_graphql,
      version: @version,
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      deps: deps(),
      name: "EctoGraphql",
      source_url: @github_url,
      homepage_url: @github_url,
      docs: docs()
    ]
  end

  defp docs do
    [
      main: "EctoGraphql",
      source_ref: "v#{@version}",
      source_url: @github_url,
      extras: [
        "README.md": [title: "Overview"]
      ],
      groups_for_modules: [
        Core: [
          EctoGraphql
        ],
        Generator: [
          EctoGraphql.Generator,
          EctoGraphql.SchemaLoader
        ],
        "Mix Tasks": [
          Mix.Tasks.Gql.Gen,
          Mix.Tasks.Gql.Gen.Init
        ]
      ]
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
      {:ex_doc, "~> 0.31", only: :dev, runtime: false},
      {:ecto_sql, "~> 3.10"}
    ]
  end

  defp description do
    "Derives GraphQL schemas, types, and resolvers from Ecto schemas for Phoenix applications using Absinthe."
  end

  defp package do
    [
      name: "ecto_graphql",
      licenses: ["MIT"],
      links: %{"GitHub" => @github_url}
    ]
  end
end
