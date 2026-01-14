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

    List of `{field_name, graphql_type}` tuples

  ## Examples

      iex> SchemaHelper.extract_fields(MyApp.Accounts.User)
      [{:id, :id}, {:email, :string}, {:name, :string}]
  """
  def extract_fields(module) do
    :fields
    |> module.__schema__()
    |> Enum.map(fn field ->
      type = module.__schema__(:type, field)
      {field, map_type(type)}
    end)
  end

  @doc """
  Maps an Ecto type to its corresponding GraphQL type.

  ## Parameters

    * `ecto_type` - The Ecto type atom or tuple

  ## Returns

    The corresponding GraphQL type atom

  ## Examples

      iex> SchemaHelper.map_type(:string)
      :string

      iex> SchemaHelper.map_type(:utc_datetime)
      :datetime

      iex> SchemaHelper.map_type({:array, :string})
      :json
  """
  def map_type(:binary_id), do: :id
  def map_type(:id), do: :id
  def map_type(:string), do: :string
  def map_type(:boolean), do: :boolean
  def map_type(:integer), do: :integer
  def map_type(:float), do: :float
  def map_type(:decimal), do: :decimal
  def map_type(:date), do: :date
  def map_type(:time), do: :time
  def map_type(:time_usec), do: :time
  def map_type(:naive_datetime), do: :naive_datetime
  def map_type(:naive_datetime_usec), do: :naive_datetime
  def map_type(:utc_datetime), do: :datetime
  def map_type(:utc_datetime_usec), do: :datetime
  def map_type({:array, _}), do: :json
  def map_type(:map), do: :json
  def map_type({:map, _}), do: :json
  def map_type(_), do: :string
end
