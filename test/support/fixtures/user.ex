defmodule EctoGraphql.Fixtures.User do
  use Ecto.Schema

  schema "users" do
    field(:name, :string)
    field(:age, :integer)
    field(:is_active, :boolean)
    field(:meta, :map)
    field(:status, Ecto.Enum, values: [:active, :inactive])
    field(:aaa, Ecto.UUID)
  end
end
