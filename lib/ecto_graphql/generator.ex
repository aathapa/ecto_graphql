defmodule EctoGraphql.Generator do
  @type_module :ecto_graphql
               |> :code.priv_dir()
               |> Path.join("templates/types/module.eex")
               |> File.read!()

  @type_block :ecto_graphql
              |> :code.priv_dir()
              |> Path.join("templates/types/block.eex")
              |> File.read!()

  @schema_module :ecto_graphql
                 |> :code.priv_dir()
                 |> Path.join("templates/schema/module.eex")
                 |> File.read!()

  @schema_block :ecto_graphql
                |> :code.priv_dir()
                |> Path.join("templates/schema/block.eex")
                |> File.read!()

  @resolver_module :ecto_graphql
                   |> :code.priv_dir()
                   |> Path.join("templates/resolvers/module.eex")
                   |> File.read!()

  @resolver_block :ecto_graphql
                  |> :code.priv_dir()
                  |> Path.join("templates/resolvers/block.eex")
                  |> File.read!()

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

  defp get_template(:type, :block), do: @type_block
  defp get_template(:type, :module), do: @type_module
  defp get_template(:schema, :block), do: @schema_block
  defp get_template(:schema, :module), do: @schema_module
  defp get_template(:resolver, :block), do: @resolver_block
  defp get_template(:resolver, :module), do: @resolver_module

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
