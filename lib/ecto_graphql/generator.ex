defmodule EctoGraphql.Generator do
  @moduledoc """
  Template-based code generator for GraphQL schemas, types, and resolvers.

  Uses EEx templates from `priv/templates/` loaded at runtime.

  ## Template Types

  - `:type` - GraphQL object and input_object definitions
  - `:schema` - Query and mutation field definitions
  - `:resolver` - Resolver function stubs

  Each has `module.eex` (wrapper) and `block.eex` (content) templates.
  """

  @doc """
  Generates or updates a GraphQL file.

  ## Parameters

  - `graphql_type` - `:type`, `:schema`, or `:resolver`
  - `file_path` - Target file path
  - `bindings` - Template variables (app, context, schema, fields, etc.)
  """
  def generate(graphql_type, file_path, bindings) do
    new_content = eex_content(graphql_type, bindings, :block)

    if File.exists?(file_path) do
      Mix.shell().info("Updating #{file_path}...")
      content = File.read!(file_path)
      updated_content = String.replace(content, ~r/end\s*$/, "\n#{new_content}end")
      File.write!(file_path, updated_content)
      Mix.Task.run("format", [file_path])
    else
      Mix.shell().info("Creating #{file_path}...")
      content = eex_content(graphql_type, bindings, :module)
      full_content = String.replace(content, "# content go here", new_content)
      Mix.Generator.create_file(file_path, full_content, format_elixir: true)
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
