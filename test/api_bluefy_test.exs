defmodule ApiBluefyTest do
  use ExUnit.Case
  doctest ApiBluefy

  test "greets the world" do
    assert ApiBluefy.hello() == :world
  end
end
