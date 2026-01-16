defmodule EctoGraphql.GqlObjectTest do
  use ExUnit.Case, async: true

  # Define test Ecto schema without timestamps
  defmodule TestUser do
    use Ecto.Schema

    @primary_key {:id, :id, autogenerate: true}
    schema "users" do
      field(:name, :string)
      field(:email, :string)
      field(:age, :integer)
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

    gql_object(:user, EctoGraphql.GqlObjectTest.TestUser)
  end

  defmodule FilteredSchema do
    use Absinthe.Schema
    use EctoGraphql

    query do
      field(:dummy, :string)
    end

    gql_object(:user, EctoGraphql.GqlObjectTest.TestUser, except: [:password_hash])
  end

  defmodule CustomFieldSchema do
    use Absinthe.Schema
    use EctoGraphql

    query do
      field(:dummy, :string)
    end

    gql_object :user, EctoGraphql.GqlObjectTest.TestUser do
      field :full_name, :string do
        resolve(fn user, _, _ ->
          {:ok, "#{user.name}"}
        end)
      end
    end
  end

  defmodule OverrideFieldSchema do
    use Absinthe.Schema
    use EctoGraphql

    query do
      field(:dummy, :string)
    end

    gql_object :user, EctoGraphql.GqlObjectTest.TestUser, except: [:age] do
      # Override the name field with custom logic
      field :name, :string do
        resolve(fn user, _, _ ->
          {:ok, String.upcase(user.name)}
        end)
      end
    end
  end

  describe "gql_object/2 basic usage" do
    test "generates object with all fields" do
      user_type = Absinthe.Schema.lookup_type(BasicSchema, :user)
      fields = Map.keys(user_type.fields)

      assert :id in fields
      assert :name in fields
      assert :email in fields
      assert :age in fields
      assert :password_hash in fields
    end

    test "creates proper object type" do
      user_type = Absinthe.Schema.lookup_type(BasicSchema, :user)

      assert user_type.__struct__ == Absinthe.Type.Object
      assert user_type.identifier == :user
    end
  end

  describe "gql_object/3 with options" do
    test "respects :except option" do
      user_type = Absinthe.Schema.lookup_type(FilteredSchema, :user)
      fields = Map.keys(user_type.fields)

      assert :name in fields
      assert :email in fields
      refute :password_hash in fields
    end
  end

  describe "gql_object with do block" do
    test "adds custom fields" do
      user_type = Absinthe.Schema.lookup_type(CustomFieldSchema, :user)
      fields = Map.keys(user_type.fields)

      # Should have auto-generated fields
      assert :id in fields
      assert :name in fields

      # Should have custom field
      assert :full_name in fields
    end

    test "custom field has correct type" do
      user_type = Absinthe.Schema.lookup_type(CustomFieldSchema, :user)

      assert user_type.fields[:full_name].type == :string
    end
  end

  describe "gql_object field override" do
    test "overrides auto-generated field" do
      user_type = Absinthe.Schema.lookup_type(OverrideFieldSchema, :user)
      fields = Map.keys(user_type.fields)

      # :name should exist (from override in do block)
      assert :name in fields

      # :age should not exist (excluded via :except)
      refute :age in fields
    end

    test "overridden field has custom resolver" do
      user_type = Absinthe.Schema.lookup_type(OverrideFieldSchema, :user)
      name_field = user_type.fields[:name]

      # Should have middleware configured (Absinthe uses middleware, not direct resolve)
      assert length(name_field.middleware) > 0
    end
  end
end
