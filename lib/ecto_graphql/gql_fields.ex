defmodule EctoGraphql.GqlFields do
  defmacro gql_fields(schema_module, opts \\ []) do
    ast =
      schema_module
      |> Macro.expand(__CALLER__)
      |> EctoGraphql.GqlFields.__define_fields__(opts)

    quote do
      (unquote_splicing(ast))
    end
  end

  def __define_fields__(schema_module, opts) do
    ensure_ecto_schema!(schema_module)
    all_fields = EctoGraphql.SchemaHelper.extract_fields(schema_module)
    filtered_fields = filter_fields(all_fields, opts)

    for {field_name, field_type} <- filtered_fields do
      quote do
        field(unquote(field_name), unquote(field_type))
      end
    end
  end

  defp filter_fields(all_fields, opts) do
    only = Keyword.get(opts, :only)
    except = Keyword.get(opts, :except, [])

    cond do
      only && except != [] ->
        raise ArgumentError, "gql_fields/2 accepts either :only or :except, not both"

      only ->
        Enum.filter(all_fields, &(elem(&1, 0) in only))

      except ->
        Enum.filter(all_fields, &(elem(&1, 0) not in except))

      true ->
        all_fields
    end
  end

  defp ensure_ecto_schema!(module) do
    with {:error, _} <- Code.ensure_compiled(module),
         false <- function_exported?(module, :__schema__, 1) do
      raise ArgumentError, """
      #{inspect(module)} is not an Ecto schema.

      gql_fields/2 expects a module using Ecto.Schema.
      """
    end
  end
end
