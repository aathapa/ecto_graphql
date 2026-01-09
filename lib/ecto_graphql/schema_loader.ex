defmodule EctoGraphql.SchemaLoader do
  @moduledoc """
  Loads an Ecto schema from a file and extracts its fields and types.
  """

  @doc """
  Loads the schema from the given file path and returns the list of fields.

  Returns `{:ok, %{module: module, source: source, fields: fields}}` or `{:error, reason}`.
  """
  def load(file_path) do
    with {:ok, module} <- compile_file(file_path),
         {:ok, schema_module} <- find_schema_module(module),
         source when is_binary(source) <- schema_module.__schema__(:source) do
      {:ok,
       %{
         module: schema_module,
         source: String.trim_trailing(source, "s"),
         fields: extract_fields(schema_module)
       }}
    end
  end

  defp compile_file(file_path) do
    if File.exists?(file_path) do
      [{module, _}] = Code.compile_file(file_path)
      {:ok, module}
    else
      {:error, :enoent}
    end
  end

  defp find_schema_module(module) do
    if function_exported?(module, :__schema__, 1),
      do: {:ok, module},
      else: {:error, :no_schema_found}
  end

  defp extract_fields(module) do
    :fields
    |> module.__schema__()
    |> Enum.map(fn field ->
      type = module.__schema__(:type, field)
      {field, map_type(type)}
    end)
  end

  defp map_type(:binary_id), do: :id
  defp map_type(:id), do: :id
  defp map_type(:string), do: :string
  defp map_type(:boolean), do: :boolean
  defp map_type(:integer), do: :integer
  defp map_type(:float), do: :float
  defp map_type(:decimal), do: :decimal
  defp map_type(:date), do: :date
  defp map_type(:time), do: :time
  defp map_type(:time_usec), do: :time
  defp map_type(:naive_datetime), do: :naive_datetime
  defp map_type(:naive_datetime_usec), do: :naive_datetime
  defp map_type(:utc_datetime), do: :datetime
  defp map_type(:utc_datetime_usec), do: :datetime
  defp map_type({:array, _}), do: :json
  defp map_type(:map), do: :json
  defp map_type({:map, _}), do: :json
  defp map_type(_), do: :string
end
