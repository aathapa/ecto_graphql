defmodule GqlGenTest do
  use ExUnit.Case
  doctest GqlGen

  test "greets the world" do
    assert GqlGen.hello() == :world
  end
end
