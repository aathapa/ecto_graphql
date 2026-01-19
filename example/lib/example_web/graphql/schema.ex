defmodule ExampleWeb.Graphql.Schema do
  use Absinthe.Schema

  import_types(Absinthe.Type.Custom)
  import_types(ExampleWeb.Graphql.Types)

  @spec context(map()) :: map()
  def context(ctx) do
    loader =
      Dataloader.new()
      |> Dataloader.add_source(:ecto, Dataloader.Ecto.new(Example.Repo))

    Map.put(ctx, :loader, loader)
  end

  @spec plugins() :: [Absinthe.Plugin.t()]
  def plugins do
    [Absinthe.Middleware.Dataloader] ++ Absinthe.Plugin.defaults()
  end

  query do
    import_fields(:user_queries)

    field :get, :string do
      resolve(fn _, _, _ -> {:ok, "user"} end)
    end
  end

  mutation do
    import_fields(:user_mutations)

    field :create, :string do
      resolve(fn _, _, _ -> {:ok, "user"} end)
    end
  end
end
