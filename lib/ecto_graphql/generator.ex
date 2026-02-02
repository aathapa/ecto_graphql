defmodule EctoGraphql.Generator do
  @moduledoc """
  Template-based code generator for GraphQL schemas, types, and resolvers.

  The Generator module reads EEx templates from `priv/templates/` and generates
  complete GraphQL files. It handles both creating new files and updating existing
  files without overwriting custom code.

  ## Template Structure

  Templates are organized by GraphQL component type:

      priv/templates/
      ├── types/
      │   ├── module.eex   # Module wrapper for types
      │   └── block.eex    # Type definitions to inject
      ├── schema/
      │   ├── module.eex   # Module wrapper for schema
      │   └── block.eex    # Query/mutation definitions
      └── resolvers/
          ├── module.eex   # Module wrapper for resolvers
          └── block.eex    # Resolver functions

  ## Available Template Variables

  All templates have access to these assigns:

    * `@app` - Application name atom (e.g., `:my_app`)
    * `@base` - Base module name string (e.g., `"MyApp"`)
    * `@web_mod` - Web module name string (e.g., `"MyAppWeb"`)
    * `@context` - Context name string (e.g., `"Accounts"`)
    * `@context_slug` - Lowercase context (e.g., `"accounts"`)
    * `@schema` - Schema name string (e.g., `"User"`)
    * `@schema_singular` - Lowercase singular (e.g., `"user"`)
    * `@schema_plural` - Lowercase plural (e.g., `"users"`)
    * `@fields` - List of `{field_name, field_type}` tuples

  ## Example Usage

      # Generate types file
      Generator.generate(
        "lib/my_app_web/graphql/accounts/type.ex",
        :type,
        [
          app: :my_app,
          context: "Accounts",
          schema: "User",
          fields: [{:id, :id}, {:name, :string}, {:email, :string}]
        ]
      )

  ## Customizing Templates

  You can customize the generated code by modifying the EEx templates in
  `priv/templates/`. For example, to add authorization to all resolvers,
  edit `priv/templates/resolvers/block.eex`:

      def list_<%= @schema_plural %>(_parent, _args, %{context: %{current_user: user}}) do
        if authorized?(user, :list, <%= @schema %>) do
          {:ok, <%= @context %>.list_<%= @schema_plural %>()}
        else
          {:error, "Unauthorized"}
        end
      end
  """

  @doc """
  Generates or updates a GraphQL file from templates.

  Creates a new file if it doesn't exist, or appends new content to an existing
  file without overwriting custom code.

  ## Parameters

    * `file_path` - Target file path (absolute or relative to project root)
    * `graphql_type` - The type of GraphQL file: `:type`, `:schema`, or `:resolver`
    * `bindings` - Keyword list of template variables

  ## Examples

      # Create a new types file (recommended)
      Generator.generate("lib/my_app_web/graphql/accounts/type.ex", :type, bindings)

      # Update an existing schema file
      Generator.generate("lib/my_app_web/graphql/accounts/schema.ex", :schema, bindings)

      # Old argument order (deprecated, but still supported)
      Generator.generate(:type, "lib/my_app_web/graphql/accounts/type.ex", bindings)

  ## Behavior

  - If the file doesn't exist, generates a complete module using `module.eex`
  - If the file exists, appends new definitions using `block.eex`
  - Automatically runs `mix format` on the generated file
  - Never overwrites custom code you've added

  ## Deprecation Notice

  The old argument order `generate(graphql_type, file_path, bindings)` is deprecated.
  Please use `generate(file_path, graphql_type, bindings)` instead.
  """
  def generate(file_path, graphql_type, bindings)

  # New signature: generate(file_path, graphql_type, bindings)
  def generate(file_path, graphql_type, bindings) when is_binary(file_path) do
    do_generate(file_path, graphql_type, bindings)
  end

  # Old signature (deprecated): generate(graphql_type, file_path, bindings)
  def generate(graphql_type, file_path, bindings) when is_atom(graphql_type) do
    IO.warn("""
    Calling Generator.generate/3 with (graphql_type, file_path, bindings) is deprecated.
    Please use (file_path, graphql_type, bindings) instead.

    Old: Generator.generate(:type, "path/to/file.ex", bindings)
    New: Generator.generate("path/to/file.ex", :type, bindings)
    """, Macro.Env.stacktrace(__ENV__))

    do_generate(file_path, graphql_type, bindings)
  end

  defp do_generate(file_path, graphql_type, bindings) do
    new_content = eex_content(graphql_type, bindings, :block)

    if File.exists?(file_path) do
      Mix.shell().info("Updating #{file_path}...")

      file_path
      |> File.read!()
      |> String.replace(~r/end\s*$/, "\n#{new_content}end")
      |> then(&File.write!(file_path, &1))

      Mix.Task.run("format", [file_path])
    else
      Mix.shell().info("Creating #{file_path}...")

      graphql_type
      |> eex_content(bindings, :module)
      |> String.replace("# content go here", new_content)
      |> then(&Mix.Generator.create_file(file_path, &1, format_elixir: true))
    end
  end

  defp eex_content(graphql, bindings, eex_content_for) do
    graphql
    |> get_template(eex_content_for)
    |> EEx.eval_string(assigns: bindings)
  end

  defp get_template(:type, :block), do: read_template("templates/types/block.eex")
  defp get_template(:type, :module), do: read_template("templates/types/module.eex")
  defp get_template(:schema, :block), do: read_template("templates/schema/block.eex")
  defp get_template(:schema, :module), do: read_template("templates/schema/module.eex")
  defp get_template(:resolver, :block), do: read_template("templates/resolvers/block.eex")
  defp get_template(:resolver, :module), do: read_template("templates/resolvers/module.eex")

  defp read_template(path) do
    :ecto_graphql
    |> :code.priv_dir()
    |> Path.join(path)
    |> File.read!()
  end

  def inject_before_final_end(content, new_content) do
    String.replace(content, ~r/end\s*$/, "\n#{new_content}\nend")
  end

  def inject_into_block(content, block_name, injection) do
    if String.contains?(content, injection) do
      content
    else
      String.replace(
        content,
        ~r/(#{block_name}\s+do)/,
        "\\1\n    #{injection}"
      )
    end
  end

  def inject_after_match(content, regex, injection) do
    String.replace(content, regex, "\\1\n#{injection}")
  end
end
