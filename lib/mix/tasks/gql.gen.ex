defmodule Mix.Tasks.Gql.Gen do
  @shortdoc "Generates an Absinthe GraphQL schema, type, and resolver for a resource"

  @moduledoc """
  Generates an Absinthe GraphQL schema, type, and resolver for a resource.

      $ mix gql.gen Accounts user name:string age:integer
      $ mix gql.gen Accounts lib/my_app/accounts/user.ex

  The first argument is the context name (e.g. `Accounts`).
  The second argument is the schema name (e.g. `user`) OR a path to an Ecto schema file.

  If a file path is provided:
  - The schema name is inferred from the table name (source) of the Ecto schema.
  - The fields are extracted from the Ecto schema definitions.

  You can also explicitly provide the schema name with a file path:
      $ mix gql.gen Accounts User lib/my_app/accounts/user.ex
  """

  use Mix.Task

  alias EctoGraphql.Generator

  @requirements ["app.start"]

  @impl true
  def run(args) do
    if Mix.Project.umbrella?() do
      Mix.raise("mix gql.gen can only be run within an application directory")
    end

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

    Generator.generate(:type, file_path, binding)
  end

  defp update_resolver(binding) do
    dir_path = "lib/#{binding[:app]}_web/graphql/#{binding[:context_slug]}"
    File.mkdir_p!(dir_path)
    file_path = Path.join(dir_path, "resolvers.ex")
    Generator.generate(:resolver, file_path, binding)
  end

  def update_schema(binding) do
    dir_path = "lib/#{binding[:app]}_web/graphql/#{binding[:context_slug]}"
    File.mkdir_p!(dir_path)

    file_path = Path.join(dir_path, "schema.ex")
    Generator.generate(:schema, file_path, binding)
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
        new_content = Generator.inject_before_final_end(content, import_line)
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
        |> Generator.inject_into_block("query", query_import)
        |> Generator.inject_into_block("mutation", mutation_import)

      if new_content != content do
        Mix.shell().info("Injecting fields into #{root_schema_path}...")
        File.write!(root_schema_path, new_content)
        Mix.Task.run("format", [root_schema_path])
      end
    end
  end

  defp parse_args(args) do
    {_opts, parsed, _invalid} = OptionParser.parse(args, switches: [], aliases: [])

    case parsed do
      [context, arg2] ->
        handle_args(context, arg2)

      [context, schema, arg3] ->
        handle_args(context, schema, arg3)

      [context, schema | fields] ->
        {context, schema, parse_fields(fields)}

      _ ->
        raise_invalid_args()
    end
  end

  # Two arguments: Context and schema file path
  defp handle_args(context, arg) do
    if schema_file?(arg) do
      load_from_file(context, nil, arg)
    else
      raise_invalid_args()
    end
  end

  # Three arguments: Context, Schema name, and either file path or field
  defp handle_args(context, schema, arg) do
    if schema_file?(arg) do
      load_from_file(context, schema, arg)
    else
      # Single field provided: Context Schema field:type
      {context, schema, parse_fields([arg])}
    end
  end

  defp schema_file?(path), do: String.ends_with?(path, ".ex")

  defp load_from_file(context, schema, file) do
    case EctoGraphql.SchemaLoader.load(file) do
      {:ok, %{source: source, fields: fields}} ->
        schema_name = schema || source
        {context, schema_name, fields}

      _ ->
        Mix.raise("Could not load schema from #{file}")
    end
  end

  defp raise_invalid_args do
    Mix.raise("""
    Invalid arguments.

    Usage:
        mix gql.gen Accounts User name:string age:integer
        mix gql.gen Accounts User lib/app/schema/user.ex
        mix gql.gen Accounts lib/app/schema/user.ex
    """)
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
end
