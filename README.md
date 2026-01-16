# EctoGraphql

[![Hex Version](https://img.shields.io/hexpm/v/ecto_graphql.svg)](https://hex.pm/packages/ecto_graphql)
[![Hex Docs](https://img.shields.io/badge/hexdocs-lightgreen.svg)](https://hexdocs.pm/ecto_graphql)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

`ecto_graphql` is a **library for deriving Absinthe GraphQL APIs from Ecto schemas**.

It derives:

* GraphQL **object and input types** from Ecto schemas
* **Query and mutation** definitions
* **Resolver stubs** ready for your business logic
* Automatic **integration** with your root schema

The goal is to eliminate repetitive boilerplate by deriving your GraphQL API directly from your Ecto schemas.

## Installation

Add the dependency to your `mix.exs`:

```elixir
def deps do
  [
    {:ecto_graphql, "~> 0.2.0"}
  ]
end
```

Then run:

```bash
mix deps.get
```

## What Gets Generated

Using a single Mix task, EctoGraphql generates:

* **GraphQL types** — object types and input types for mutations
* **Queries** — list all and get by ID
* **Mutations** — create, update, and delete operations
* **Resolvers** — function stubs for you to implement business logic
* **Automatic imports** — seamless integration into your root schema

All generated code is **plain Elixir** that you can modify, extend, or refactor as needed.

## Mix Task

### From Ecto Schema (Recommended)

```bash
mix gql.gen Accounts lib/example/accounts/user.ex
```

This reads the Ecto schema file and automatically:

1. Extracts all schema fields
2. Maps Ecto types to GraphQL types
3. Generates type definitions, queries, mutations, and resolvers
4. Integrates generated modules into your root schema

### Override Schema Name

```bash
mix gql.gen Accounts Person lib/example/accounts/user.ex
```

Use this when your GraphQL schema name should differ from the Ecto table name.

### Manual Field Definition

```bash
mix gql.gen Accounts User name:string email:string age:integer
```

For quick prototyping or when you don't have an Ecto schema yet.


## Generated File Structure

For context `Accounts` and schema `User`, the generator creates:

```
lib/example_web/graphql/accounts/
├── type.ex       # GraphQL object and input types
├── schema.ex     # Query and mutation definitions
└── resolvers.ex  # Resolver function stubs
```

Existing files are updated intelligently without overwriting your custom code.

## Example Ecto Schema

```elixir
defmodule MyApp.Accounts.User do
  use Ecto.Schema

  schema "users" do
    field :name, :string
    field :email, :string
    field :password_hash, :string

    timestamps(type: :utc_datetime)
  end
end
```

## Runtime Macros

EctoGraphql provides two powerful macros for defining GraphQL types at compile-time from your Ecto schemas:

- **`gql_object`** - Creates complete object definitions
- **`gql_fields`** - Generates field definitions within existing objects

### Quick Start

```elixir
defmodule MyAppWeb.Schema.Types do
  use Absinthe.Schema.Notation
  use EctoGraphql

  # Complete object definition
  gql_object(:user, MyApp.Accounts.User)

  # Or use gql_fields within an object
  object :product do
    gql_fields(MyApp.Catalog.Product)
  end
end
```

### `gql_object` - Complete Object Definitions

Use `gql_object` to quickly create a complete GraphQL object from an Ecto schema.

#### Basic Usage

```elixir
# Generate all fields
gql_object(:user, MyApp.Accounts.User)
```

#### Field Filtering

```elixir
# Include only specific fields
gql_object(:user_public, MyApp.Accounts.User, only: [:id, :name, :email])

# Exclude sensitive fields
gql_object(:user, MyApp.Accounts.User, except: [:password_hash, :recovery_token])
```

#### Custom Fields

Add or override fields using a `do` block:

```elixir
gql_object :user, MyApp.Accounts.User do
  # Add a custom field
  field :full_name, :string do
    resolve fn user, _, _ ->
      {:ok, "#{user.first_name} #{user.last_name}"}
    end
  end
  
  # Override an auto-generated field
  field :email, :string do
    resolve fn user, _, _ ->
      if user.email_public, do: {:ok, user.email}, else: {:ok, "[hidden]"}
    end
  end
end
```

#### Combining Options and Custom Fields

```elixir
gql_object :user, MyApp.Accounts.User, except: [:inserted_at, :updated_at] do
  field :member_since, :string do
    resolve fn user, _, _ ->
      days = DateTime.diff(DateTime.utc_now(), user.inserted_at, :day)
      {:ok, "#{days} days"}
    end
  end
end
```

### `gql_fields` - Field Generation

Use `gql_fields` when you need fine-grained control over your object structure.

#### Basic Usage

```elixir
object :user do
  gql_fields(MyApp.Accounts.User)
end
```

#### Mixing with Custom Fields

```elixir
object :user do
  gql_fields(MyApp.Accounts.User, except: [:password_hash])
  
  # Add custom fields
  field :avatar_url, :string do
    resolve fn user, _, _ ->
      {:ok, "https://cdn.example.com/avatars/#{user.id}.jpg"}
    end
  end
  
  field :is_admin, :boolean do
    resolve fn user, _, _ ->
      {:ok, user.role == :admin}
    end
  end
end
```

#### Multiple Schemas in One Object

```elixir
object :user_profile do
  gql_fields(MyApp.Accounts.User, only: [:id, :name, :email])
  gql_fields(MyApp.Accounts.Profile, except: [:user_id, :id])
  
  # Add computed fields
  field :display_name, :string
end
```

#### When to Use Each Macro

**Use `gql_object` when:**
- You want a quick, complete object definition
- Most fields map directly from your Ecto schema
- You only need to add a few custom fields

**Use `gql_fields` when:**
- You need precise control over field ordering
- You're combining fields from multiple schemas
- You want to mix auto-generated and custom fields explicitly
- You're building complex object structures

## Mix Tasks

Generate GraphQL schemas, types, and resolvers from Ecto schemas using Mix tasks:

### Generate from Ecto Schema

```bash
mix gql.gen Accounts lib/my_app/accounts/user.ex
```

This generates:
- `lib/my_app_web/graphql/accounts/types.ex` - Object and input_object types
- `lib/my_app_web/graphql/accounts/schema.ex` - Query and mutation definitions  
- `lib/my_app_web/graphql/accounts/resolvers.ex` - Resolver function stubs

### Initialize

```bash
mix gql.gen.init
```

## Generated GraphQL Types

```elixir
object :user do
  field(:id, :id)
  field(:name, :string)
  field(:email, :string)
  field(:inserted_at, :datetime)
  field(:updated_at, :datetime)
end

input_object :user_params do
  field(:id, :id)
  field(:name, :string)
  field(:email, :string)
  field(:inserted_at, :datetime)
  field(:updated_at, :datetime)
end
```

## Generated Resolvers

Resolver stubs are created for you to implement your business logic:

```elixir
def list_users(_parent, _args, _resolution) do
  {:ok, Accounts.list_users()}
end

def get_user(_parent, %{id: id}, _resolution) do
  Accounts.get_user!(id)
end

def create_user(_parent, args, _resolution) do
  Accounts.create_user(args)
end

def update_user(_parent, %{id: id} = args, _resolution) do
  user = Accounts.get_user!(id)
  Accounts.update_user(user, args)
end
```

This preserves the separation between your GraphQL layer and business logic.

## Automatic Schema Integration

Generated modules are automatically imported into your root schema:

**lib/example_web/graphql/types.ex**:
```elixir
defmodule ExampleWeb.Graphql.Types do
  use Absinthe.Schema.Notation

  # Import generated types here
  import_types(ExampleWeb.Graphql.Accounts.Schema)
end
```

**lib/example_web/graphql/schema.ex**:
```elixir
defmodule ExampleWeb.Graphql.Schema do
  use Absinthe.Schema

  import_types(Absinthe.Type.Custom)
  import_types(ExampleWeb.Graphql.Types)

  query do
    import_fields(:user_queries)
  end

  mutation do
    import_fields(:user_mutations)
  end
end
```

No manual wiring required. If these files don't exist, they'll be created for you.

## Type Mapping

Ecto types are intelligently mapped to GraphQL types:

| Ecto Type       | GraphQL Type |
| --------------- | ------------ |
| `:binary_id`    | `:id`        |
| `:string`       | `:string`    |
| `:integer`      | `:integer`   |
| `:boolean`      | `:boolean`   |
| `:utc_datetime` | `:datetime`  |
| `:map`          | `:json`      |

See the [full documentation](https://hexdocs.pm/ecto_graphql) for complete type mapping reference.

## Features

- ✅ **Automatic field extraction** from Ecto schemas
- ✅ **Smart type mapping** (Ecto → GraphQL)
- ✅ **Table name singularization** (`users` → `user`)
- ✅ **Auto-integration** with existing schemas
- ✅ **Customizable EEx templates** in `priv/templates`
- ✅ **Incremental updates** — doesn't overwrite existing files
- ✅ **Phoenix-friendly** structure and conventions

## Philosophy

EctoGraphql follows these principles:

* **Generated code is yours** — modify, extend, or refactor as needed
* **No runtime magic** — plain Absinthe code you can read and understand
* **Explicit over clever** — predictable generation, no surprises
* **Single source of truth** — Ecto schemas drive your GraphQL API

If the generated code is hard to read or modify, it doesn't belong here.



## Documentation

Full documentation is available on HexDocs:  
[https://hexdocs.pm/ecto_graphql](https://hexdocs.pm/ecto_graphql)

## License

MIT
