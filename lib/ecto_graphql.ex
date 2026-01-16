defmodule EctoGraphql do
  @moduledoc """
  Derives Absinthe GraphQL schemas, types, and resolvers from Ecto schemas.

  EctoGraphql provides two ways to generate GraphQL types from Ecto schemas:

  1. **Mix Tasks** - Generate code files for types, schemas, and resolvers
  2. **Runtime Macro** - Define GraphQL objects at compile-time using the `gql_object` macro

  ## Mix Task Usage

  Generate from an Ecto schema file:

      mix gql.gen Accounts lib/my_app/accounts/user.ex

  Generate with manual field definitions:

      mix gql.gen Accounts User name:string email:string age:integer

  Override the inferred schema name:

      mix gql.gen Accounts CustomUser lib/my_app/accounts/user.ex

  ## Runtime Macro Usage

  Import the macros in your Absinthe schema modules:

      defmodule MyAppWeb.Schema.Types do
        use Absinthe.Schema.Notation
        use EctoGraphql

        # Basic usage
        gql_object(:user, MyApp.Accounts.User)

        # With field filtering
        gql_object(:admin_user, MyApp.Accounts.User, only: [:id, :name, :email])

        # With custom fields
        gql_object(:user, MyApp.Accounts.User) do
          field :full_name, :string, resolve: fn user, _, _ ->
            {:ok, "\#{user.first_name} \#{user.last_name}"}
          end
        end
      end

  ## What the Mix Task Generates

  For each schema, creates three files in `lib/my_app_web/graphql/<context>/`:

  - `type.ex` - GraphQL object and input_object types
  - `schema.ex` - Query and mutation field definitions
  - `resolvers.ex` - Resolver function stubs

  ## Type Mapping

  Ecto types are automatically mapped to GraphQL types:

  - `:binary_id` → `:id`
  - `:string` → `:string`
  - `:integer` → `:integer`
  - `:boolean` → `:boolean`
  - `:utc_datetime` → `:datetime`
  - `:map`, `{:array, _}` → `:json`

  See `EctoGraphql.SchemaLoader` for complete type mapping.
  """

  defmacro __using__(_opts) do
    quote do
      import EctoGraphql.GqlFields
      import EctoGraphql.GqlObject
    end
  end
end
