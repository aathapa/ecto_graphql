defmodule EctoGraphql.GqlFields do
  @moduledoc """
  Provides the `gql_fields/2` macro for generating Absinthe field definitions from Ecto schemas.

  The `gql_fields` macro extracts field information from an Ecto schema and generates
  corresponding Absinthe field definitions, including associations with dataloader resolvers.

  Use gql_fields to insert auto-generated fields at a specific location within an object block.

  ## Basic Usage

  Use within an `object` block to generate fields from your Ecto schema:

      object :user do
        gql_fields(MyApp.Accounts.User)
      end

  This will generate field definitions for all fields in the schema: `:id`, `:name`,
  `:email`, etc., with appropriate GraphQL types.

  ## Association Support

  Associations (has_one, has_many, belongs_to) are automatically detected and
  generated with dataloader resolvers:

      # If User has_many :posts, generates:
      # field :posts, list_of(:post), resolve: dataloader(:ecto)

      # If User belongs_to :organization, generates:
      # field :organization, :organization, resolve: dataloader(:ecto)

  Make sure to import the dataloader helper and configure your schema:

      import Absinthe.Resolution.Helpers, only: [dataloader: 1]

  ## Field Filtering

  ### Using `:only`

  Include only specific fields:

      object :user_public do
        gql_fields(MyApp.Accounts.User, only: [:id, :name, :email])

        # Add custom fields after
        field :display_name, :string do
          resolve fn user, _, _ ->
            {:ok, String.upcase(user.name)}
          end
        end
      end

  ### Using `:except`

  Exclude sensitive or unwanted fields:

      object :user do
        gql_fields(MyApp.Accounts.User, except: [:password_hash, :password])
      end

  ## When to Use

  Choose `gql_fields` over `gql_object` when you need to:

  - Mix auto-generated fields with custom fields in a specific order
  - Combine fields from multiple Ecto schemas into one GraphQL object
  - Define the object structure explicitly rather than having it generated

  Otherwise, use `gql_object` for simpler, complete object definitions.
  """

  @type field_opts :: [only: [atom()]] | [except: [atom()]] | []

  @doc """
  Generates Absinthe field definitions from an Ecto schema.

  ## Parameters

    * `schema_module` - The Ecto schema module to extract fields from
    * `opts` - Optional keyword list:
      * `:only` - List of field names to include (atoms)
      * `:except` - List of field names to exclude (atoms)

  You cannot specify both `:only` and `:except` - an `ArgumentError` will be raised.

  ## Examples

      # Generate all fields
      object :user do
        gql_fields(MyApp.Accounts.User)
      end

      # Include only specific fields
      object :user_minimal do
        gql_fields(MyApp.Accounts.User, only: [:id, :email])
      end

      # Exclude sensitive fields
      object :user_safe do
        gql_fields(MyApp.Accounts.User, except: [:password_hash, :recovery_token])
      end

      # Mix with custom fields
      object :user_extended do
        gql_fields(MyApp.Accounts.User, except: [:inserted_at, :updated_at])

        field :full_name, :string do
          resolve fn user, _, _ ->
            {:ok, "\#{user.first_name} \#{user.last_name}"}
          end
        end

        field :avatar_url, :string
      end

  ## Error Cases

  Raises `ArgumentError` if:
  - Both `:only` and `:except` options are provided
  - The provided module is not an Ecto schema

  """
  @spec gql_fields(module(), field_opts()) :: Macro.t()
  defmacro gql_fields(schema_module, opts \\ []) do
    ast =
      schema_module
      |> Macro.expand(__CALLER__)
      |> EctoGraphql.GqlFields.__define_fields__(opts)

    quote do
      (unquote_splicing(ast))
    end
  end

  @doc false
  def __define_fields__(schema_module, opts) do
    ensure_ecto_schema!(schema_module)
    all_fields = EctoGraphql.SchemaHelper.extract_fields(schema_module)
    filtered_fields = filter_by_field_name(all_fields, opts)

    field_asts =
      for {field_name, field_type} <- filtered_fields do
        quote do
          field(unquote(field_name), unquote(field_type))
        end
      end

    association_asts = build_association_asts(schema_module, opts)

    field_asts ++ association_asts
  end

  defp build_association_asts(schema_module, opts) do
    if Keyword.get(opts, :include_associations, true) == false do
      []
    else
      all_associations = EctoGraphql.SchemaHelper.extract_associations(schema_module)
      filtered_associations = filter_by_field_name(all_associations, opts)

      for {assoc_name, assoc_type, cardinality} <- filtered_associations do
        gql_type =
          case cardinality do
            :one -> assoc_type
            :many -> quote(do: list_of(unquote(assoc_type)))
          end

        quote do
          field(unquote(assoc_name), unquote(gql_type),
            resolve: Absinthe.Resolution.Helpers.dataloader(:ecto)
          )
        end
      end
    end
  end

  defp filter_by_field_name(items, opts) do
    only = Keyword.get(opts, :only)
    except = Keyword.get(opts, :except, [])

    cond do
      only && except != [] ->
        raise ArgumentError, "gql_fields/2 accepts either :only or :except, not both"

      only ->
        Enum.filter(items, &(elem(&1, 0) in only))

      except != [] ->
        Enum.filter(items, &(elem(&1, 0) not in except))

      true ->
        items
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
