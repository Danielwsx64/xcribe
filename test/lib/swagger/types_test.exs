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

    test "return type as string for not know types" do
      assert Types.type_for(nil) == "string"
      assert Types.type_for({}) == "string"
      assert Types.type_for(:ok) == "string"
      assert Types.type_for(self()) == "string"
    end
  end

  describe "format_for/1" do
    test "return format for given values" do
      assert Types.format_for(1) == "int32"
      assert Types.format_for(1.0) == "float"
    end

    test "return empty for not know formats" do
      assert Types.format_for(true) == ""
      assert Types.format_for("a") == ""
      assert Types.format_for(nil) == ""
      assert Types.format_for({}) == ""
      assert Types.format_for(:ok) == ""
      assert Types.format_for(self()) == ""
    end
  end
end
