defmodule EctoGraphql.EnumTest do
  use ExUnit.Case

  defmodule TestUser do
    use Ecto.Schema

    schema "users" do
      field(:name, :string)
      field(:status, Ecto.Enum, values: [:active, :inactive, :pending])
      field(:role, Ecto.Enum, values: [:admin, :user, :guest])
    end
  end

  describe "SchemaHelper.extract_fields/1 with enums" do
    test "detects enum fields and extracts values" do
      fields = EctoGraphql.SchemaHelper.extract_fields(TestUser)

      # Find the status field
      {_name, status_type} = Enum.find(fields, fn {name, _} -> name == :status end)
      assert {:enum, :test_user_status, [:active, :inactive, :pending]} = status_type

      # Find the role field
      {_name, role_type} = Enum.find(fields, fn {name, _} -> name == :role end)
      assert {:enum, :test_user_role, [:admin, :user, :guest]} = role_type
    end

    test "generates correct enum names" do
      enum_name = EctoGraphql.SchemaHelper.generate_enum_name(TestUser, :status)
      assert enum_name == :test_user_status

      role_name = EctoGraphql.SchemaHelper.generate_enum_name(TestUser, :role)
      assert role_name == :test_user_role
    end
  end

  describe "gql_enums" do
    test "generates enum type definitions with compact syntax" do
      enum_ast = EctoGraphql.GqlFields.__define_enums__(TestUser, [])

      # Should generate both enum types using compact values: syntax
      code = Macro.to_string(enum_ast)
      assert code =~ "enum(:test_user_status, values: [:active, :inactive, :pending])"
      assert code =~ "enum(:test_user_role, values: [:admin, :user, :guest])"
    end

    test "filters enum types with :only option" do
      enum_ast = EctoGraphql.GqlFields.__define_enums__(TestUser, only: [:status])

      code = Macro.to_string(enum_ast)
      assert code =~ "test_user_status"
      refute code =~ "test_user_role"
    end

    test "excludes enum types with :except option" do
      enum_ast = EctoGraphql.GqlFields.__define_enums__(TestUser, except: [:status])

      code = Macro.to_string(enum_ast)
      refute code =~ "test_user_status"
      assert code =~ "test_user_role"
    end
  end

  describe "gql_fields with enums" do
    test "generates fields that reference enum types" do
      field_ast = EctoGraphql.GqlFields.__define_fields__(TestUser, [])

      code = Macro.to_string(field_ast)
      # Fields should reference the enum type names
      assert code =~ "field(:status, :test_user_status)"
      assert code =~ "field(:role, :test_user_role)"
    end

    test "filters enum fields with :only option" do
      ast = EctoGraphql.GqlFields.__define_fields__(TestUser, only: [:id, :status])

      code = Macro.to_string(ast)
      assert code =~ "field(:id, :id)"
      assert code =~ "field(:status, :test_user_status)"
      refute code =~ ":role"
    end

    test "excludes enum fields with :except option" do
      ast = EctoGraphql.GqlFields.__define_fields__(TestUser, except: [:status])

      code = Macro.to_string(ast)
      refute code =~ ":status"
      assert code =~ "field(:role, :test_user_role)"
    end
  end

  describe "gql_object with enums" do
    test "generates complete object with enum fields in schema" do
      defmodule TestSchema do
        use Absinthe.Schema

        query do
          field(:dummy, :string)
        end

        defmodule Types do
          use Absinthe.Schema.Notation
          use EctoGraphql

          # Define enums first
          gql_enums(TestUser)

          # Then define object
          gql_object(:test_user_obj, TestUser)
        end

        import_types(Types)
      end

      # Verify enum types exist in schema
      status_enum = Absinthe.Schema.lookup_type(TestSchema, :test_user_status)
      assert status_enum != nil
      assert status_enum.name == "TestUserStatus"
      status_values = status_enum.values |> Map.values() |> Enum.map(& &1.value)
      assert :active in status_values
      assert :inactive in status_values
      assert :pending in status_values

      role_enum = Absinthe.Schema.lookup_type(TestSchema, :test_user_role)
      assert role_enum != nil
      assert role_enum.name == "TestUserRole"
      role_values = role_enum.values |> Map.values() |> Enum.map(& &1.value)
      assert :admin in role_values
      assert :user in role_values
      assert :guest in role_values

      # Verify object has enum fields
      user_type = Absinthe.Schema.lookup_type(TestSchema, :test_user_obj)
      assert user_type != nil
      assert user_type.fields[:status].type == :test_user_status
      assert user_type.fields[:role].type == :test_user_role
    end

    test "enum types work with non_null option" do
      defmodule TestNonNullSchema do
        use Absinthe.Schema

        query do
          field(:dummy, :string)
        end

        defmodule Types do
          use Absinthe.Schema.Notation
          use EctoGraphql

          gql_enums(TestUser)
          gql_object(:test_user_non_null, TestUser, non_null: [:id, :status])
        end

        import_types(Types)
      end

      # Verify status field is non_null
      user_type = Absinthe.Schema.lookup_type(TestNonNullSchema, :test_user_non_null)
      assert %Absinthe.Type.NonNull{of_type: :test_user_status} = user_type.fields[:status].type
    end
  end
end
