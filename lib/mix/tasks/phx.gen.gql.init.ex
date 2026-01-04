defmodule Mix.Tasks.Phx.Gen.Gql.Init do
  @shortdoc "Initializes Absinthe GraphQL in a Phoenix project"

  @moduledoc """
  Initializes Absinthe GraphQL in a Phoenix project.

      $ mix phx.gen.gql.init

  This task:
  1. Creates `lib/my_app_web/graphql/schema.ex` (Root Schema).
  2. Creates `lib/my_app_web/graphql/types.ex` (Agreggator).
  3. Injects `Absinthe.Plug` routes into `lib/my_app_web/router.ex`.
  """

  use Mix.Task

  @requirements ["app.start"]

  @impl true
  def run(_args) do
    if Mix.Project.umbrella?() do
      Mix.raise("mix phx.gen.gql.init can only be run within an application directory")
    end

    app = Mix.Project.config()[:app]
    base = Macro.camelize(Atom.to_string(app))
    web_mod = base <> "Web"

    binding = [
      app: app,
      base: base,
      web_mod: web_mod
    ]

    create_schema_file(binding)
    create_types_aggregator(binding)
    inject_router_config(binding)
    inject_dependencies()

    Mix.shell().info("GraphQL initialization complete!")
  end

  defp create_schema_file(binding) do
    content = schema_template(binding)
    file_path = "lib/#{binding[:app]}_web/graphql/schema.ex"
    Mix.Generator.create_file(file_path, content)
  end

  defp create_types_aggregator(binding) do
    content = types_aggregator_template(binding)
    file_path = "lib/#{binding[:app]}_web/graphql/types.ex"
    Mix.Generator.create_file(file_path, content)
  end

  defp inject_dependencies do
    mix_path = "mix.exs"

    if File.exists?(mix_path) do
      content = File.read!(mix_path)

      if String.contains?(content, ":absinthe") do
        Mix.shell().info("Absinthe dependencies already present.")
      else
        Mix.shell().info("Injecting Absinthe dependencies into mix.exs...")

        new_deps = """
            {:absinthe, "~> 1.9.0"},
            {:absinthe_plug, "~> 1.5.9"},
        """

        new_content = Regex.replace(~r/(defp deps do\s+\[)/, content, "\\1\n#{new_deps}")

        if new_content != content do
          File.write!(mix_path, new_content)
          Mix.shell().info("Dependencies injected. Run `mix deps.get` to install them.")
        else
          Mix.shell().error(
            "Could not safely inject dependencies. Please add {:absinthe, \"~> 1.7\"} manually."
          )
        end
      end
    else
      Mix.shell().error("Could not find mix.exs")
    end
  end

  defp inject_router_config(binding) do
    router_path = "lib/#{binding[:app]}_web/router.ex"

    if File.exists?(router_path) do
      Mix.shell().info("Injecting GraphQL routes into #{router_path}...")

      file_content = File.read!(router_path)

      if String.contains?(file_content, "/graphql") do
        Mix.shell().info("GraphQL routes already appear to be present. Skipping injection.")
      else
        new_content = inject_routes(file_content, binding)
        File.write!(router_path, new_content)
      end
    else
      Mix.shell().error(
        "Could not find router at #{router_path}. Please add the GraphQL routes manually."
      )
    end
  end

  defp inject_routes(content, binding) do
    routes_code = """

      scope "/" do
        pipe_through :api

        forward "/graphiql", Absinthe.Plug.GraphiQL,
          schema: #{binding[:web_mod]}.Graphql.Schema,
          interface: :playground

        forward "/graphql", Absinthe.Plug,
          schema: #{binding[:web_mod]}.Graphql.Schema
      end
    """

    lines = String.split(content, "\n")

    {reversed_pre, reversed_post} =
      Enum.split_while(Enum.reverse(lines), fn line ->
        !String.match?(String.trim(line), ~r/^end$/)
      end)

    case reversed_post do
      [last_end | rest] ->
        new_lines = Enum.reverse(rest) ++ [routes_code, last_end] ++ Enum.reverse(reversed_pre)
        Enum.join(new_lines, "\n")

      _ ->
        Mix.shell().error("Could not safely inject routes. Please add them manually.")
        content
    end
  end

  require EEx

  EEx.function_from_string(
    :defp,
    :schema_template,
    """
    defmodule <%= @web_mod %>.Graphql.Schema do
      use Absinthe.Schema

      import_types <%= @web_mod %>.Graphql.Type

      @spec context(map()) :: map()
      def context(ctx) do
        ctx
      end

      query do
        field :get_user, :string do
          resolve fn _, _, _ -> {:ok, "user"} end
        end
      end

      mutation do
        field :create_user, :string do
          resolve fn _, _, _ -> {:ok, "user"} end
        end
      end
    end
    """,
    [:assigns]
  )

  EEx.function_from_string(
    :defp,
    :types_aggregator_template,
    """
    defmodule <%= @web_mod %>.Graphql.Type do
      use Absinthe.Schema.Notation

      # Import generated types here
    end
    """,
    [:assigns]
  )
end
