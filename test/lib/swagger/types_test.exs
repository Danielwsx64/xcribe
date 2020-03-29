defmodule Xcribe.Swagger.TypesTest do
  use ExUnit.Case, async: true

  alias Xcribe.Swagger.Types

  describe "type_for/1" do
    test "return type for given values" do
      assert Types.type_for("a") == "string"
      assert Types.type_for(1) == "number"
      assert Types.type_for(1.0) == "number"
      assert Types.type_for(true) == "boolean"
    end
  end

  describe "format_for/1" do
    test "return format for given values" do
      assert Types.format_for("a") == ""
      assert Types.format_for(1) == "int32"
      assert Types.format_for(1.0) == "float"
      assert Types.format_for(true) == ""
    end
  end
end
