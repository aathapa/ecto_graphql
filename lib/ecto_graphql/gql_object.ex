defmodule EctoGraphql.GqlObject do
  defmacro gql_object(name, schema_module) do
    generate_object(name, schema_module, [], nil)
  end

  defmacro gql_object(name, schema_module, do: block) do
    generate_object(name, schema_module, [], block)
  end

  defmacro gql_object(name, schema_module, opts) do
    generate_object(name, schema_module, opts, nil)
  end

  defmacro gql_object(name, schema_module, opts, do: block) do
    generate_object(name, schema_module, opts, block)
  end

  defp generate_object(name, schema_module, opts, do_block) do
    overridden_fields = if do_block, do: extract_field_names(do_block), else: []
    filtered_opts = filter_overridden_fields(overridden_fields, opts)

    quote do
      object(unquote(name)) do
        EctoGraphql.GqlFields.gql_fields(unquote(schema_module), unquote(filtered_opts))
        unquote(do_block)
      end
    end
  end

  defp extract_field_names({:__block__, _, expressions}) do
    Enum.flat_map(expressions, &extract_field_names/1)
  end

  defp extract_field_names({:field, _, [name | _]}) when is_atom(name) do
    [name]
  end

  defp extract_field_names(_), do: []

  defp filter_overridden_fields(overridden_fields, opts) do
    case {Keyword.get(opts, :except), overridden_fields} do
      {nil, []} -> opts
      {nil, overridden_fields} -> Keyword.put(opts, :except, overridden_fields)
      {except, _} -> Keyword.put(opts, :except, except ++ overridden_fields)
    end
  end
end
