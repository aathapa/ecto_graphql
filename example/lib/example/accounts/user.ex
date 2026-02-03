defmodule Example.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :name, :string
    field :email, :string
    field :status, Ecto.Enum, values: [:active, :inactive, :pending]
    field :role, Ecto.Enum, values: [:admin, :user, :guest]
    has_one :profile, Example.Accounts.Profile

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:name, :email, :status, :role])
    |> validate_required([:name, :email])
  end
end
