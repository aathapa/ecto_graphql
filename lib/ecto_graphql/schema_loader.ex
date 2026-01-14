defmodule EctoGraphql.SchemaLoader do
  @moduledoc """
  Loads Ecto schema files and extracts field information.

  SchemaLoader uses Elixir's code compilation and Ecto's reflection API to read
  schema files and extract table names and field types. It then maps Ecto types
  to appropriate GraphQL types.

  ## How It Works

  1. Compiles the Ecto schema file using `Code.compile_file/1`
  2. Verifies the module implements Ecto.Schema via `__schema__/1` callback
  3. Extracts the table name using `__schema__(:source)`
  4. Reads all fields and their types using `__schema__(:fields)` and `__schema__(:type, field)`
  5. Maps each Ecto type to a GraphQL type

  ## Type Mapping

  Automatically maps Ecto types to GraphQL types (e.g., `:string` → `:string`,
  `:utc_datetime` → `:datetime`, `:map` → `:json`).

  ## Example

      # Load a schema file
      {:ok, schema_info} = SchemaLoader.load("lib/my_app/accounts/user.ex")

      # Returns:
      %{
        module: MyApp.Accounts.User,
        source: "user",    # singularized from "users"
        fields: [
          {:id, :id},
          {:name, :string},
          {:email, :string},
          {:age, :integer},
          {:inserted_at, :datetime},
          {:updated_at, :datetime}
        ]
      }

  ## Error Handling

  Returns `{:error, reason}` if:
  - The file doesn't exist (`:enoent`)
  - The file doesn't contain an Ecto schema (`:no_schema_found`)
  - The file has compilation errors
  """

  @doc """
  Loads and parses an Ecto schema file.

  Compiles the file, extracts the schema module, table name, and all field
  definitions with their types.

  ## Parameters

    * `file_path` - Path to the Ecto schema file (e.g., `"lib/my_app/accounts/user.ex"`)

  ## Returns

    * `{:ok, schema_info}` where `schema_info` is a map containing:
      * `:module` - The compiled Ecto schema module
      * `:source` - The singularized table name (e.g., `"users"` becomes `"user"`)
      * `:fields` - List of `{field_name, graphql_type}` tuples

    * `{:error, :enoent}` if the file doesn't exist
    * `{:error, :no_schema_found}` if the module isn't an Ecto schema

  ## Examples

      iex> SchemaLoader.load("lib/my_app/accounts/user.ex")
      {:ok, %{
        module: MyApp.Accounts.User,
        source: "user",
        fields: [{:id, :id}, {:email, :string}, {:name, :string}]
      }}

      iex> SchemaLoader.load("nonexistent.ex")
      {:error, :enoent}
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
