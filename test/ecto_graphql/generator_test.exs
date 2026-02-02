defmodule EctoGraphql.GeneratorTest do
  use ExUnit.Case
  
  import ExUnit.CaptureIO
  alias EctoGraphql.Generator

  @test_dir "/tmp/ecto_graphql_test"
  
  setup do
    File.rm_rf!(@test_dir)
    File.mkdir_p!(@test_dir)
    :ok
  end

  describe "generate/3 argument order" do
    test "accepts new argument order (file_path, graphql_type, bindings)" do
      file_path = Path.join(@test_dir, "new_order.ex")
      
      bindings = [
        web_mod: "TestWeb",
        context: "Accounts",
        schema_module: "Test.Accounts.User",
        schema: "User",
        schema_singular: "user",
        schema_plural: "users",
        fields: [{:id, :id}, {:name, :string}]
      ]

      # New order: file_path first (no deprecation warning)
      output = capture_io(:stdio, fn ->
        Generator.generate(file_path, :type, bindings)
      end)

      assert File.exists?(file_path)
      refute output =~ "deprecated"
    end

    test "accepts old argument order (graphql_type, file_path, bindings) with deprecation warning" do
      file_path = Path.join(@test_dir, "old_order.ex")
      
      bindings = [
        web_mod: "TestWeb",
        context: "Accounts",
        schema_module: "Test.Accounts.User",
        schema: "User",
        schema_singular: "user",
        schema_plural: "users",
        fields: [{:id, :id}, {:name, :string}]
      ]

      # Old order: graphql_type first (shows deprecation warning)
      output = capture_io(:stderr, fn ->
        Generator.generate(:type, file_path, bindings)
      end)

      assert File.exists?(file_path)
      assert output =~ "deprecated"
      assert output =~ "Generator.generate/3 with (graphql_type, file_path, bindings) is deprecated"
    end

    test "both argument orders produce identical output" do
      file_path_new = Path.join(@test_dir, "compare_new.ex")
      file_path_old = Path.join(@test_dir, "compare_old.ex")
      
      bindings = [
        web_mod: "TestWeb",
        context: "Accounts",
        schema_module: "Test.Accounts.User",
        schema: "User",
        schema_singular: "user",
        schema_plural: "users",
        fields: [{:id, :id}, {:email, :string}]
      ]

      # Generate with both orders
      capture_io(:stdio, fn ->
        Generator.generate(file_path_new, :type, bindings)
      end)
      
      capture_io(:stderr, fn ->
        Generator.generate(:type, file_path_old, bindings)
      end)

      # Both should produce the same file content
      content_new = File.read!(file_path_new)
      content_old = File.read!(file_path_old)
      
      assert content_new == content_old
    end
  end
end
