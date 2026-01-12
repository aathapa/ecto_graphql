defmodule ExampleWeb.Graphql.Schema do
  use Absinthe.Schema

  import_types(Absinthe.Type.Custom)
  import_types(ExampleWeb.Graphql.Types)

  @spec context(map()) :: map()
  def context(ctx) do
    ctx
  end

  query do
    field :get, :string do
      resolve(fn _, _, _ -> {:ok, "user"} end)
    end
  end

  mutation do
    field :create, :string do
      resolve(fn _, _, _ -> {:ok, "user"} end)
    end
  end
end
