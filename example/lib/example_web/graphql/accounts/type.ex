defmodule ExampleWeb.Graphql.Accounts.Types do
  use Absinthe.Schema.Notation
  use EctoGraphql

  @moduledoc """
  GraphQL types for the Accounts context.
  """

  gql_object(:user, Example.Accounts.User)
  gql_input_object(:user_params, Example.Accounts.User)

  gql_object(:profile, Example.Accounts.Profile)
  gql_input_object(:profile_params, Example.Accounts.Profile)
end
