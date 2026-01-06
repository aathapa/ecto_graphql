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

    IO.inspect(binding, label: "binding")

    update_type(binding)
    inject_context_import(binding)

    Mix.shell().info("Generated GraphQL files for #{schema}!")
  end

  defp inject_context_import(binding) do
    types_aggregator_path = "lib/#{binding[:app]}_web/graphql/types.ex"

    if File.exists?(types_aggregator_path) do
      content = File.read!(types_aggregator_path)
      module_name = "#{binding[:web_mod]}.Graphql.#{binding[:context]}.Types"
      import_line = "import_types #{module_name}"

      if String.contains?(content, module_name) do
        :ok
      else
        Mix.shell().info("Injecting context import into #{types_aggregator_path}...")
        new_content = String.replace(content, ~r/end\s*$/, "\n#{import_line}\nend")
        File.write!(types_aggregator_path, new_content)
        Mix.Task.run("format", [types_aggregator_path])
      end
    end
  end

  defp update_type(binding) do
    dir_path = "lib/#{binding[:app]}_web/graphql/#{binding[:context_slug]}"
    File.mkdir_p!(dir_path)

    file_path = Path.join(dir_path, "type.ex")
    new_type_content = type_block_template(binding)

    if File.exists?(file_path) do
      Mix.shell().info("Updating #{file_path}...")
      content = File.read!(file_path)
      updated_content = Regex.replace(~r/end\s*$/, content, "\n#{new_type_content}\nend")
      File.write!(file_path, updated_content)
      Mix.Task.run("format", [file_path])
    else
      Mix.shell().info("Creating #{file_path}...")
      content = context_types_module_template(binding)
      full_content = String.replace(content, "# types go here", new_type_content)
      Mix.Generator.create_file(file_path, full_content, format_elixir: true)
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
end
