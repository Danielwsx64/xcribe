defmodule XcribeTest do
  use ExUnit.Case
  doctest Xcribe

  test "greets the world" do
    assert Xcribe.hello() == :world
  end
end
