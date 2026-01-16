defmodule EctoGraphql.GqlFieldsTest do
  use ExUnit.Case, async: true

  # Define test Ecto schemas without timestamps
  defmodule TestUser do
    use Ecto.Schema

    @primary_key {:id, :id, autogenerate: true}
    schema "users" do
      field(:name, :string)
      field(:email, :string)
      field(:age, :integer)
      field(:is_active, :boolean)
      field(:password_hash, :string)
    end
  end

  # Define test Absinthe schemas using the macros
  defmodule BasicSchema do
    use Absinthe.Schema
    use EctoGraphql

    query do
      field(:dummy, :string)
    end

    object :user do
      gql_fields(EctoGraphql.GqlFieldsTest.TestUser)
    end
  end

  defmodule FilteredOnlySchema do
    use Absinthe.Schema
    use EctoGraphql

    query do
      field(:dummy, :string)
    end

    object :user do
      gql_fields(EctoGraphql.GqlFieldsTest.TestUser, only: [:id, :name, :email])
    end
  end

  defmodule FilteredExceptSchema do
    use Absinthe.Schema
    use EctoGraphql

    query do
      field(:dummy, :string)
    end

    object :user do
      gql_fields(EctoGraphql.GqlFieldsTest.TestUser, except: [:password_hash])
    end
  end

  describe "gql_fields/2 basic usage" do
    test "generates all fields from Ecto schema" do
      user_type = Absinthe.Schema.lookup_type(BasicSchema, :user)
      fields = Map.keys(user_type.fields)

      assert :id in fields
      assert :name in fields
      assert :email in fields
      assert :age in fields
      assert :is_active in fields
      assert :password_hash in fields
    end

    test "maps types correctly" do
      user_type = Absinthe.Schema.lookup_type(BasicSchema, :user)

      assert user_type.fields[:id].type == :id
      assert user_type.fields[:name].type == :string
      assert user_type.fields[:email].type == :string
      assert user_type.fields[:age].type == :integer
      assert user_type.fields[:is_active].type == :boolean
    end
  end

  describe "gql_fields/2 with :only option" do
    test "includes only specified fields" do
      user_type = Absinthe.Schema.lookup_type(FilteredOnlySchema, :user)
      fields = Map.keys(user_type.fields)

      assert :id in fields
      assert :name in fields
      assert :email in fields

      # These should NOT be included
      refute :age in fields
      refute :password_hash in fields
    end

    test "has correct field count" do
      user_type = Absinthe.Schema.lookup_type(FilteredOnlySchema, :user)
      fields = Map.keys(user_type.fields)

      # :id, :name, :email, plus __typename
      assert length(fields) == 4
    end
  end

  describe "gql_fields/2 with :except option" do
    test "excludes specified fields" do
      user_type = Absinthe.Schema.lookup_type(FilteredExceptSchema, :user)
      fields = Map.keys(user_type.fields)

      # These should be included
      assert :id in fields
      assert :name in fields
      assert :email in fields
      assert :age in fields

      # password_hash should be excluded
      refute :password_hash in fields
    end

    test "has correct field count" do
      user_type = Absinthe.Schema.lookup_type(FilteredExceptSchema, :user)
      fields = Map.keys(user_type.fields)

      # 6 total fields - 1 excluded + __typename = 6
      assert length(fields) == 6
    end
  end
end
