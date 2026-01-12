defmodule ExampleWeb.Graphql.Accounts.Schema do
  use Absinthe.Schema.Notation
  alias ExampleWeb.Graphql.Accounts.Resolvers

  import_types(ExampleWeb.Graphql.Accounts.Types)

  @moduledoc """
  GraphQL schema for the Accounts context.
  """

  object :user_queries do
    field :list_users, list_of(:user) do
      resolve(&Resolvers.list_users/3)
    end

    field :get_user, :user do
      arg(:id, non_null(:id))
      resolve(&Resolvers.get_user/3)
    end
  end

  object :user_mutations do
    field :create_user, :user do
      arg(:user_params, non_null(:user_params))
      resolve(&Resolvers.create_user/3)
    end

    field :update_user, :user do
      arg(:id, non_null(:id))
      arg(:user_params, non_null(:user_params))
      resolve(&Resolvers.update_user/3)
    end
  end
end
