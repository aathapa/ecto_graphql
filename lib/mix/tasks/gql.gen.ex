defmodule Mix.Tasks.Gql.Gen do
  @shortdoc "Generates an Absinthe GraphQL schema, type, and resolver for a resource"

  @moduledoc """
  Generates an Absinthe GraphQL schema, type, and resolver for a resource.

      $ mix gql.gen Accounts user name:string age:integer

  The first argument is the context name (e.g. `Accounts`).
  The second argument is the schema name (e.g. `user`).
  The remaining arguments are the schema fields.
  """

  use Mix.Task

  @requirements ["app.start"]

  @impl true
  def run(args) do
    if Mix.Project.umbrella?() do
      Mix.raise("mix gql.gen can only be run within an application directory")
    end

    IO.inspect(args, label: "args")

    {context, schema, fields} = parse_args(args)

    app = Mix.Project.config()[:app]
    base = Macro.camelize(Atom.to_string(app))
    web_mod = base <> "Web"
    context_slug = String.downcase(context)

    binding = [
      app: app,
      base: base,
      web_mod: web_mod,
      context: context,
      context_slug: context_slug,
      schema: schema,
      fields: fields,
      schema_plural: String.downcase(schema) <> "s",
      schema_singular: String.downcase(schema)
    ]

    update_type(binding)
    update_resolver(binding)
    update_schema(binding)
    inject_schema_import(binding)
    inject_root_fields(binding)

    Mix.shell().info("Generated GraphQL files for #{schema}!")
  end

  defp update_type(binding) do
    dir_path = "lib/#{binding[:app]}_web/graphql/#{binding[:context_slug]}"
    File.mkdir_p!(dir_path)

    file_path = Path.join(dir_path, "type.ex")
    new_type_content = type_block_template(binding)

    if File.exists?(file_path) do
      Mix.shell().info("Updating #{file_path}...")
      content = File.read!(file_path)
      updated_content = String.replace(content, ~r/end\s*$/, "\n#{new_type_content}\nend")
      File.write!(file_path, updated_content)
      Mix.Task.run("format", [file_path])
    else
      Mix.shell().info("Creating #{file_path}...")
      content = context_types_module_template(binding)
      full_content = String.replace(content, "# types go here", new_type_content)
      Mix.Generator.create_file(file_path, full_content, format_elixir: true)
    end
  end

  defp update_resolver(binding) do
    dir_path = "lib/#{binding[:app]}_web/graphql/#{binding[:context_slug]}"
    File.mkdir_p!(dir_path)

    file_path = Path.join(dir_path, "resolvers.ex")
    new_resolver_content = resolver_functions_template(binding)

    if File.exists?(file_path) do
      Mix.shell().info("Updating #{file_path}...")
      content = File.read!(file_path)
      updated_content = String.replace(content, ~r/end\s*$/, "\n#{new_resolver_content}\nend")
      File.write!(file_path, updated_content)
      Mix.Task.run("format", [file_path])
    else
      Mix.shell().info("Creating #{file_path}...")
      content = resolver_module_template(binding)
      full_content = String.replace(content, "# resolvers go here", new_resolver_content)
      Mix.Generator.create_file(file_path, full_content, format_elixir: true)
    end
  end

  def update_schema(binding) do
    dir_path = "lib/#{binding[:app]}_web/graphql/#{binding[:context_slug]}"
    File.mkdir_p!(dir_path)

    file_path = Path.join(dir_path, "schema.ex")
    new_schema_content = schema_template(binding)

    if File.exists?(file_path) do
      Mix.shell().info("Updating #{file_path}...")
      content = File.read!(file_path)
      updated_content = String.replace(content, ~r/end\s*$/, "\n#{new_schema_content}\nend")
      File.write!(file_path, updated_content)
      Mix.Task.run("format", [file_path])
    else
      Mix.shell().info("Creating #{file_path}...")
      content = schema_module_template(binding)
      full_content = String.replace(content, "# schema go here", new_schema_content)
      Mix.Generator.create_file(file_path, full_content, format_elixir: true)
    end
  end

  defp inject_schema_import(binding) do
    types_aggregator_path = "lib/#{binding[:app]}_web/graphql/types.ex"

    if File.exists?(types_aggregator_path) do
      content = File.read!(types_aggregator_path)
      module_name = "#{binding[:web_mod]}.Graphql.#{binding[:context]}.Schema"
      import_line = "import_types #{module_name}"

      if String.contains?(content, module_name) do
        :ok
      else
        Mix.shell().info("Injecting schema import into #{types_aggregator_path}...")
        new_content = String.replace(content, ~r/end\s*$/, "\n#{import_line}\nend")
        File.write!(types_aggregator_path, new_content)
        Mix.Task.run("format", [types_aggregator_path])
      end
    end
  end

  defp inject_root_fields(binding) do
    root_schema_path = "lib/#{binding[:app]}_web/graphql/schema.ex"

    if File.exists?(root_schema_path) do
      content = File.read!(root_schema_path)

      query_import = "import_fields :#{binding[:schema_singular]}_queries"
      mutation_import = "import_fields :#{binding[:schema_singular]}_mutations"

      new_content =
        content
        |> inject_into_block("query", query_import)
        |> inject_into_block("mutation", mutation_import)

      if new_content != content do
        Mix.shell().info("Injecting fields into #{root_schema_path}...")
        File.write!(root_schema_path, new_content)
        Mix.Task.run("format", [root_schema_path])
      end
    end
  end

  defp inject_into_block(content, block_name, injection) do
    if String.contains?(content, injection) do
      content
    else
      String.replace(content, ~r/(#{block_name}\s+do)/, "\\1\n    #{injection}")
    end
  end

  defp parse_args(args) do
    {_opts, parsed, _invalid} = OptionParser.parse(args, switches: [], aliases: [])

    case parsed do
      [context, schema | fields] ->
        {context, schema, parse_fields(fields)}

      _ ->
        Mix.raise("""
        Invalid arguments.

        Usage:
            mix gql.gen Accounts User name:string age:integer
        """)
    end
  end

  defp parse_fields(fields) do
    Enum.map(fields, fn field ->
      case String.split(field, ":", parts: 2) do
        [name, type] -> {String.to_atom(name), String.to_atom(type)}
        [name] -> {String.to_atom(name), :string}
      end
    end)
  end

  require EEx

  # Template for the Context Types Module (created once)
  EEx.function_from_string(
    :defp,
    :context_types_module_template,
    """
    defmodule <%= @web_mod %>.Graphql.<%= @context %>.Types do
      use Absinthe.Schema.Notation

      # types go here
    end
    """,
    [:assigns]
  )

  # Template for a single Type Block
  EEx.function_from_string(
    :defp,
    :type_block_template,
    """
      object :<%= @schema_singular %> do
        field :id, :id
    <%= for {name, type} <- @fields do %>    field :<%= name %>, :<%= type %>
    <% end %>  end

      input_object :<%= @schema_singular %>_params do
    <%= for {name, type} <- @fields do %>    field :<%= name %>, :<%= type %>
    <% end %>  end
    """,
    [:assigns]
  )

  # Template for the Resolver Module (created once)
  EEx.function_from_string(
    :defp,
    :resolver_module_template,
    """
    defmodule <%= @web_mod %>.Graphql.<%= @context %>.Resolvers do
      alias <%= @base %>.<%= @context %>

      # resolvers go here
    end
    """,
    [:assigns]
  )

  # Template for Resolver Functions
  EEx.function_from_string(
    :defp,
    :resolver_functions_template,
    """
      def list_<%= @schema_plural %>(_parent, _args, _resolution) do
        {:ok, <%= @context %>.list_<%= @schema_plural %>()}
      end

      def get_<%= @schema_singular %>(_parent, %{id: id}, _resolution) do
        case <%= @context %>.get_<%= @schema_singular %>(id) do
          nil -> {:error, "Not found"}
          <%= @schema_singular %> -> {:ok, <%= @schema_singular %>}
        end
      end

      def create_<%= @schema_singular %>(_parent, args, _resolution) do
        <%= @context %>.create_<%= @schema_singular %>(args)
      end

      def update_<%= @schema_singular %>(_parent, %{id: id} = args, _resolution) do
        <%= @schema_singular %> = <%= @context %>.get_<%= @schema_singular %>(id)
        <%= @context %>.update_<%= @schema_singular %>(<%= @schema_singular %>, args)
      end
    """,
    [:assigns]
  )

  # Template for the Schema Module (created once)
  EEx.function_from_string(
    :defp,
    :schema_module_template,
    """
    defmodule <%= @web_mod %>.Graphql.<%= @context %>.Schema do
      use Absinthe.Schema.Notation
      alias <%= @web_mod %>.Graphql.<%= @context %>.Resolvers

      import_types <%= @web_mod %>.Graphql.<%= @context %>.Types

      # schema go here
    end
    """,
    [:assigns]
  )

  # Template for Schema Objects (Queries/Mutations)
  EEx.function_from_string(
    :defp,
    :schema_template,
    """
      object :<%= @schema_singular %>_queries do
        field :list_<%= @schema_plural %>, list_of(:<%= @schema_singular %>) do
          resolve &Resolvers.list_<%= @schema_plural %>/3
        end

        field :get_<%= @schema_singular %>, :<%= @schema_singular %> do
          arg :id, non_null(:id)
          resolve &Resolvers.get_<%= @schema_singular %>/3
        end
      end

      object :<%= @schema_singular %>_mutations do
        field :create_<%= @schema_singular %>, :<%= @schema_singular %> do
          arg :<%= @schema_singular %>_params, non_null(:<%= @schema_singular %>_params)
          resolve &Resolvers.create_<%= @schema_singular %>/3
        end

        field :update_<%= @schema_singular %>, :<%= @schema_singular %> do
          arg :id, non_null(:id)
          arg :<%= @schema_singular %>_params, non_null(:<%= @schema_singular %>_params)
          resolve &Resolvers.update_<%= @schema_singular %>/3
        end
      end
    """,
    [:assigns]
  )
end
