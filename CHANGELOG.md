# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.4.1] - 2025-02-07

### Added

- **Code Generator**: Mix task `mix gql.gen` now generates objects with `include_associations: false` by default to prevent the association object errors

## [0.4.0] - 2025-02-03

### Added

- **Ecto.Enum Support**: Full support for `Ecto.Enum` fields with automatic GraphQL enum type generation

  - New `gql_enums/2` macro to generate enum type definitions from Ecto schemas
  - Automatic detection of `Ecto.Enum` fields in schemas
  - Enum types use compact syntax: `enum(:user_status, values: [:active, :inactive, :pending])`
  - Enum type names follow convention: `{schema_name}_{field_name}` (e.g., `:user_status`)
  - Support for `:only` and `:except` filtering options
  - Object fields automatically reference generated enum types
  - Works seamlessly with `non_null` option for enum fields
  - Code generator templates automatically include `gql_enums` calls

- **Backward Compatibility**: `Generator.generate/3` now supports both argument orders
  - New pipe-friendly order: `generate(file_path, graphql_type, bindings)`
  - Old order still supported: `generate(graphql_type, file_path, bindings)` (deprecated)
  - Deprecation warnings guide users to new syntax
  - No breaking changes - existing code continues to work

## [0.3.1] - 2025-02-01

### Added

- **Non-null Field Support**: Added `:non_null` and `:nullable` options to `gql_object` and `gql_fields` macros
  - Fields can be marked as `non_null` by passing `non_null: [:field1, :field2]` option
  - The `:nullable` option takes precedence and can override fields marked as non-null
  - Non-null wrapping is automatically skipped for `input_object` types (input fields remain nullable)

## [0.3.0] - 2025-01-19

### Added

- **Association Support**: Automatic handling of Ecto schema associations (`has_one`, `has_many`, `belongs_to`) in GraphQL types

  - New `extract_associations/1` function in `EctoGraphql.SchemaHelper` to extract association metadata from Ecto schemas
  - Association fields are automatically generated with Dataloader resolvers in `gql_fields` macro
  - New `:include_associations` option for `gql_fields` (defaults to `true`)

- **Dataloader Integration**: Built-in support for Dataloader in generated schemas

  - `gql.gen.init` task now adds `dataloader` dependency to `mix.exs`
  - Generated root schema includes `context/1` function with Dataloader setup
  - Generated root schema includes `plugins/0` function with `Absinthe.Middleware.Dataloader`

- **Optional Dataloader Dependency**: Added `{:dataloader, "~> 2.0", optional: true}` as an optional dependency

### Changed

- Renamed `filter_by_name/2` to `filter_by_field_name/2` in `EctoGraphql.GqlFields` for clarity
- Input objects (`gql_input_object`) now automatically exclude association fields

### Fixed

- Resolved issue where association fields caused compilation errors in input object types
- Fixed Dataloader function availability by using fully qualified module path `Absinthe.Resolution.Helpers.dataloader/1`

## [0.2.0] - - 2025-01-09

### Added

- Initial release with `gql_object` and `gql_fields` macros
- `mix gql.gen` task for generating GraphQL types, schemas, and resolvers
- `mix gql.gen.init` task for initializing Absinthe in a Phoenix project
- Automatic type mapping from Ecto to GraphQL types
- Field filtering with `:only` and `:except` options
- Custom field support via `do` blocks
