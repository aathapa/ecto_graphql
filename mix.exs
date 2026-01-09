defmodule EctoGraphql.MixProject do
  use Mix.Project

  def project do
    [
      app: :ecto_graphql,
      version: "0.2.0",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      deps: deps(),
      name: "EctoGraphql",
      source_url: "https://github.com/aathapa/ecto_graphql"
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
    "A generic GraphQL generator for Phoenix applications using Absinthe."
  end

  defp package do
    [
      name: "ecto_graphql",
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/aathapa/ecto_graphql"}
    ]
  end
end
