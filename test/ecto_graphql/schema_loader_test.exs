defmodule EctoGraphql.SchemaLoaderTest do
  use ExUnit.Case
  alias EctoGraphql.SchemaLoader

  test "loads fields from an Ecto schema file" do
    path = "test/support/fixtures/user.ex"

    {:ok, %{module: module, source: source, fields: fields}} = SchemaLoader.load(path)

    assert module == EctoGraphql.Fixtures.User
    assert source == "user"

    # Note: Ecto adds :id by default
    assert {:id, :id} in fields
    assert {:name, :string} in fields
    assert {:age, :integer} in fields
    assert {:is_active, :boolean} in fields
    assert {:meta, :json} in fields
  end
end
