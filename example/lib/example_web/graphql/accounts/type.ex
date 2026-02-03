defmodule ExampleWeb.Graphql.Accounts.Types do
  use Absinthe.Schema.Notation
  use EctoGraphql

  @moduledoc """
  GraphQL types for the Accounts context.
  """

  # Generate enum types from Ecto.Enum fields
  gql_enums(Example.Accounts.User)

  # Mark id, name and email as non-null fields
  gql_object(:user, Example.Accounts.User, non_null: [:id, :name, :email])
  gql_input_object(:user_params, Example.Accounts.User)

  gql_object(:profile, Example.Accounts.Profile)
  gql_input_object(:profile_params, Example.Accounts.Profile)
end
