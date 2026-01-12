defmodule ExampleWeb.Graphql.Accounts.Types do
  use Absinthe.Schema.Notation

  @moduledoc """
  GraphQL types for the Accounts context.
  """

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
end
