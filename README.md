# EctoGraphql

Generate Absinthe GraphQL schemas, types, and resolvers from your Ecto schemas.

## Installation

Add `ecto_graphql` to your dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ecto_graphql, "~> 0.2.0"}
  ]
end
```

## Quick Start

Generate GraphQL from an existing Ecto schema:

```bash
mix gql.gen Accounts lib/my_app/accounts/user.ex
```

This automatically extracts fields from your Ecto schema and generates:

- Type definitions (`type.ex`)
- Schema with queries and mutations (`schema.ex`)
- Resolver stubs (`resolvers.ex`)

## Usage

### From Ecto Schema (Recommended)

```bash
# Infer schema name from table
mix gql.gen Blog lib/my_app/blog/post.ex

# Override schema name
mix gql.gen Blog Article lib/my_app/blog/post.ex
```

### Manual Field Definition

```bash
mix gql.gen Accounts User name:string email:string age:integer
```

## Generated Files

For context `Accounts` and schema `User`:

```
lib/my_app_web/graphql/accounts/
├── type.ex       # GraphQL object and input types
├── schema.ex     # Query and mutation definitions
└── resolvers.ex  # Resolver function stubs
```

## Type Mapping

Ecto types are automatically mapped to GraphQL types:

| Ecto            | GraphQL     |
| --------------- | ----------- |
| `:binary_id`    | `:id`       |
| `:string`       | `:string`   |
| `:integer`      | `:integer`  |
| `:boolean`      | `:boolean`  |
| `:utc_datetime` | `:datetime` |
| `:map`          | `:json`     |

See [documentation](https://hexdocs.pm/ecto_graphql) for complete mapping.

## Integration

The generator automatically integrates with your existing GraphQL schema by adding imports to:

- `lib/my_app_web/graphql/types.ex`
- `lib/my_app_web/graphql/schema.ex`

If these files don't exist, you'll need to manually import the generated modules.

## Example

Given this Ecto schema:

```elixir
defmodule MyApp.Blog.Post do
  use Ecto.Schema

  schema "posts" do
    field :title, :string
    field :body, :string
    field :published_at, :utc_datetime
    timestamps()
  end
end
```

Run:

```bash
mix gql.gen Blog lib/my_app/blog/post.ex
```

Generates GraphQL types for a `post` schema with all fields automatically extracted.

## Features

- ✅ Automatic field extraction from Ecto schemas
- ✅ Smart type mapping (Ecto → GraphQL)
- ✅ Table name singularization (`users` → `user`)
- ✅ Auto-integration with existing schemas
- ✅ Customizable EEx templates
- ✅ Updates existing files without overwriting

## Documentation

- [Hex Docs](https://hexdocs.pm/ecto_graphql)

## License

MIT
