defmodule EctoGraphql.SchemaHelper do
  @moduledoc """
  Helper functions for working with Ecto schemas and mapping types to GraphQL.

  This module provides utilities for extracting field information from Ecto schemas
  and mapping Ecto types to their corresponding GraphQL types.
  """

  @doc """
  Extracts fields from an Ecto schema module.

  ## Parameters

    * `module` - The Ecto schema module

  ## Returns

    List of `{field_name, graphql_type}` tuples. For enum fields, returns
    `{field_name, {:enum, enum_name, [values]}}` tuples.

  ## Examples

      iex> SchemaHelper.extract_fields(MyApp.Accounts.User)
      [{:id, :id}, {:email, :string}, {:name, :string}]

      iex> SchemaHelper.extract_fields(MyApp.Accounts.User) # with enum
      [{:id, :id}, {:status, {:enum, :user_status, [:active, :inactive]}}]
  """
  def extract_fields(module) do
    :fields
    |> module.__schema__()
    |> Enum.map(fn field ->
      type = module.__schema__(:type, field)
      {field, map_type(type, module, field)}
    end)
  end

  @doc """
  Maps an Ecto type to its corresponding GraphQL type.

  ## Parameters

    * `ecto_type` - The Ecto type atom or tuple
    * `module` - The Ecto schema module (optional, for enum detection)
    * `field` - The field name (optional, for enum value extraction)

  ## Returns

    The corresponding GraphQL type atom, or `{:enum, enum_name, values}` for enums

  ## Examples

      iex> SchemaHelper.map_type(:string)
      :string

      iex> SchemaHelper.map_type(:utc_datetime)
      :datetime

      iex> SchemaHelper.map_type({:array, :string})
      :json
  """
  def map_type(ecto_type, module \\ nil, field \\ nil)

  # Enum type detection (requires module and field)
  def map_type({:parameterized, {Ecto.Enum, _metadata}}, module, field)
      when not is_nil(module) and not is_nil(field) do
    values = Ecto.Enum.values(module, field)
    enum_name = generate_enum_name(module, field)
    {:enum, enum_name, values}
  end

  # Simple type mappings (delegate to helper)
  def map_type(ecto_type, _module, _field) do
    do_map_type(ecto_type)
  end

  defp do_map_type(:binary_id), do: :id
  defp do_map_type(:id), do: :id
  defp do_map_type(:string), do: :string
  defp do_map_type(:boolean), do: :boolean
  defp do_map_type(:integer), do: :integer
  defp do_map_type(:float), do: :float
  defp do_map_type(:decimal), do: :decimal
  defp do_map_type(:date), do: :date
  defp do_map_type(:time), do: :time
  defp do_map_type(:time_usec), do: :time
  defp do_map_type(:naive_datetime), do: :naive_datetime
  defp do_map_type(:naive_datetime_usec), do: :naive_datetime
  defp do_map_type(:utc_datetime), do: :datetime
  defp do_map_type(:utc_datetime_usec), do: :datetime
  defp do_map_type({:array, _}), do: :json
  defp do_map_type(:map), do: :json
  defp do_map_type({:map, _}), do: :json
  defp do_map_type(_), do: :string

  @doc """
  Generates a GraphQL enum type name from a schema module and field name.

  ## Examples

      iex> generate_enum_name(Example.Accounts.User, :status)
      :user_status

      iex> generate_enum_name(Example.Blog.Post, :visibility)
      :post_visibility
  """
  def generate_enum_name(module, field) do
    schema_name =
      module
      |> Module.split()
      |> List.last()
      |> Macro.underscore()

    "#{schema_name}_#{field}"
    |> String.to_atom()
  end

  @doc """
  Extracts associations from an Ecto schema module.

  ## Parameters

    * `module` - The Ecto schema module

  ## Returns

    List of `{field_name, graphql_type, cardinality}` tuples where:
    - `field_name` is the association field name
    - `graphql_type` is the GraphQL type (derived from related schema)
    - `cardinality` is `:one` or `:many`

  ## Examples

      iex> SchemaHelper.extract_associations(MyApp.Blog.Post)
      [{:author, :user, :one}, {:comments, :comment, :many}]
  """
  def extract_associations(module) do
    module.__schema__(:associations)
    |> Enum.map(fn assoc_name ->
      assoc = module.__schema__(:association, assoc_name)
      gql_type = association_to_gql_type(assoc.related)
      {assoc_name, gql_type, assoc.cardinality}
    end)
  end

  defp association_to_gql_type(related_module) do
    related_module
    |> Module.split()
    |> List.last()
    |> Macro.underscore()
    |> String.to_atom()
  end
end
