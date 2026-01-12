defmodule ExampleWeb.Graphql.Types do
  use Absinthe.Schema.Notation

  # Import generated types here

  import_types(ExampleWeb.Graphql.Accounts.Schema)
end
