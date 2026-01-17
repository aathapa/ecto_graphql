defmodule Mix.Tasks.Gql.Gen do
  @shortdoc "Generates Absinthe GraphQL schema, types, and resolvers"

  @moduledoc """
  Generates Absinthe GraphQL schema, types, and resolvers for a resource.

  ## Usage Patterns

  ### 1. Generate from Ecto Schema File (Recommended)

      $ mix gql.gen Accounts lib/my_app/accounts/user.ex

  This automatically:
  - Loads the Ecto schema module
  - Extracts the table name (e.g., "users" → "user")
  - Reads all field definitions and types
  - Generates GraphQL types, schema, and resolvers

  ### 2. Generate from Ecto Schema with Custom Name

      $ mix gql.gen Accounts CustomUser lib/my_app/accounts/user.ex

  Use this when you want a different GraphQL schema name than the inferred one.

  ### 3. Manual Field Definition

      $ mix gql.gen Accounts User name:string email:string age:integer

  Manually specify fields when you don't have an Ecto schema.

  ## Generated Files

  For context `Accounts` and schema `User`, generates:

  - `lib/my_app_web/graphql/accounts/type.ex` - Object and input types
  - `lib/my_app_web/graphql/accounts/schema.ex` - Query and mutation definitions
  - `lib/my_app_web/graphql/accounts/resolvers.ex` - Resolver stubs

  ## Automatic Integration

  If the following files exist, the generator automatically adds imports:

  - `lib/my_app_web/graphql/types.ex` - Adds `import_types` statement
  - `lib/my_app_web/graphql/schema.ex` - Adds `import_fields` statements

  ## Field Type Syntax

  When manually defining fields, use the format `field_name:type`:

  - `name:string` - String field
  - `age:integer` - Integer field
  - `price:decimal` - Decimal field
  - `active:boolean` - Boolean field
  - `published_at:utc_datetime` - DateTime field

  Omit the type to default to `:string`:

      $ mix gql.gen Blog Post title body:string

  This creates `title:string` and `body:string`.

  ## Examples

      # Generate from existing Ecto schema
      $ mix gql.gen Blog lib/my_app/blog/post.ex

      # Generate with custom name
      $ mix gql.gen Shop Product lib/my_app/catalog/item.ex

      # Generate manually for a simple type
      $ mix gql.gen Config Setting key:string value:string

  ## Notes

  - Generated files use proper indentation and are auto-formatted
  - Resolver functions are stubs - implement your business logic
  - Running the task multiple times appends new definitions to existing files
  - Schema names are singularized from table names (e.g., "users" → "user")
  """

  use Mix.Task

  alias EctoGraphql.Generator

  @requirements ["app.start"]

  @impl true
  def run(args) do
    if Mix.Project.umbrella?() do
      Mix.raise("mix gql.gen can only be run within an application directory")
    end

    {context, schema, fields, schema_module} = parse_args(args)

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
      schema_module: schema_module,
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
        {context, schema, parse_fields(fields), nil}

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
      {context, schema, parse_fields([arg]), nil}
    end
  end

  defp schema_file?(path), do: String.ends_with?(path, ".ex")

  defp load_from_file(context, schema, file) do
    case EctoGraphql.SchemaLoader.load(file) do
      {:ok, %{module: module, source: source, fields: fields}} ->
        schema_name = schema || source
        {context, schema_name, fields, module}

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
