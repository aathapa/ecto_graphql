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

  #
  # Input Object Tests
  #

  defmodule BasicInputSchema do
    use Absinthe.Schema
    use EctoGraphql

    query do
      field(:dummy, :string)
    end

    gql_input_object(:user_input, EctoGraphql.GqlObjectTest.TestUser)
  end

  defmodule FilteredInputSchema do
    use Absinthe.Schema
    use EctoGraphql

    query do
      field(:dummy, :string)
    end

    gql_input_object(:user_input, EctoGraphql.GqlObjectTest.TestUser, except: [:password_hash])
  end

  defmodule CustomFieldInputSchema do
    use Absinthe.Schema
    use EctoGraphql

    query do
      field(:dummy, :string)
    end

    gql_input_object :user_input, EctoGraphql.GqlObjectTest.TestUser do
      field(:password_confirmation, :string)
    end
  end

  defmodule OverrideFieldInputSchema do
    use Absinthe.Schema
    use EctoGraphql

    query do
      field(:dummy, :string)
    end

    gql_input_object :user_input, EctoGraphql.GqlObjectTest.TestUser, except: [:age] do
      # Override the name field
      field(:name, :string)
    end
  end

  describe "gql_input_object/2 basic usage" do
    test "generates input object with all fields" do
      user_input = Absinthe.Schema.lookup_type(BasicInputSchema, :user_input)
      fields = Map.keys(user_input.fields)

      assert :id in fields
      assert :name in fields
      assert :email in fields
      assert :age in fields
      assert :password_hash in fields
    end

    test "creates proper input object type" do
      user_input = Absinthe.Schema.lookup_type(BasicInputSchema, :user_input)

      assert user_input.__struct__ == Absinthe.Type.InputObject
      assert user_input.identifier == :user_input
    end
  end

  describe "gql_input_object/3 with options" do
    test "respects :except option" do
      user_input = Absinthe.Schema.lookup_type(FilteredInputSchema, :user_input)
      fields = Map.keys(user_input.fields)

      assert :name in fields
      assert :email in fields
      refute :password_hash in fields
    end
  end

  describe "gql_input_object with do block" do
    test "adds custom fields" do
      user_input = Absinthe.Schema.lookup_type(CustomFieldInputSchema, :user_input)
      fields = Map.keys(user_input.fields)

      # Should have auto-generated fields
      assert :id in fields
      assert :name in fields

      # Should have custom field
      assert :password_confirmation in fields
    end

    test "custom field has correct type" do
      user_input = Absinthe.Schema.lookup_type(CustomFieldInputSchema, :user_input)

      assert user_input.fields[:password_confirmation].type == :string
    end
  end

  describe "gql_input_object field override" do
    test "overrides auto-generated field" do
      user_input = Absinthe.Schema.lookup_type(OverrideFieldInputSchema, :user_input)
      fields = Map.keys(user_input.fields)

      # :name should exist (from override in do block)
      assert :name in fields

      # :age should not exist (excluded via :except)
      refute :age in fields
    end
  end

  #
  # Non-null Tests
  #

  defmodule NonNullExplicitSchema do
    use Absinthe.Schema
    use EctoGraphql

    query do
      field(:dummy, :string)
    end

    # Use :non_null option to mark fields as non_null
    gql_object(:user, EctoGraphql.GqlObjectTest.TestUser, non_null: [:id, :name, :email])
  end

  defmodule NullableOverrideSchema do
    use Absinthe.Schema
    use EctoGraphql

    query do
      field(:dummy, :string)
    end

    # :nullable takes precedence over :non_null
    gql_object(:user, EctoGraphql.GqlObjectTest.TestUser, 
      non_null: [:id, :name, :email], 
      nullable: [:id]
    )
  end

  defmodule InputObjectNonNullSchema do
    use Absinthe.Schema
    use EctoGraphql

    query do
      field(:dummy, :string)
    end

    # Input objects should NOT have non_null applied
    gql_input_object(:user_input, EctoGraphql.GqlObjectTest.TestUser, non_null: [:id, :name, :email])
  end

  describe "gql_object with explicit :non_null option" do
    test "wraps specified fields with non_null type" do
      user_type = Absinthe.Schema.lookup_type(NonNullExplicitSchema, :user)

      # Explicitly declared non_null fields should be wrapped
      assert user_type.fields[:id].type == %Absinthe.Type.NonNull{of_type: :id}
      assert user_type.fields[:name].type == %Absinthe.Type.NonNull{of_type: :string}
      assert user_type.fields[:email].type == %Absinthe.Type.NonNull{of_type: :string}

      # Other fields should NOT be wrapped
      assert user_type.fields[:age].type == :integer
    end
  end

  describe "gql_object with :nullable option" do
    test "nullable takes precedence over non_null" do
      user_type = Absinthe.Schema.lookup_type(NullableOverrideSchema, :user)

      # :id should be nullable (nullable takes precedence)
      assert user_type.fields[:id].type == :id

      # :name and :email should be non_null
      assert user_type.fields[:name].type == %Absinthe.Type.NonNull{of_type: :string}
      assert user_type.fields[:email].type == %Absinthe.Type.NonNull{of_type: :string}

      # Other fields are nullable by default
      assert user_type.fields[:age].type == :integer
    end
  end

  describe "gql_input_object non_null behavior" do
    test "does NOT apply non_null to input objects even with option" do
      user_input = Absinthe.Schema.lookup_type(InputObjectNonNullSchema, :user_input)

      # All fields should be nullable in input objects, even if non_null option is passed
      assert user_input.fields[:id].type == :id
      assert user_input.fields[:name].type == :string
      assert user_input.fields[:email].type == :string
      assert user_input.fields[:age].type == :integer
    end
  end
end
