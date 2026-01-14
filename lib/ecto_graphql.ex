defmodule EctoGraphql do
  @moduledoc """
  Derives Absinthe GraphQL schemas, types, and resolvers from Ecto schemas.

  ## Usage

  Generate from an Ecto schema file:

      mix gql.gen Accounts lib/my_app/accounts/user.ex

  Generate with manual field definitions:

      mix gql.gen Accounts User name:string email:string age:integer

  Override the inferred schema name:

      mix gql.gen Accounts CustomUser lib/my_app/accounts/user.ex

  ## What it generates

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
end
