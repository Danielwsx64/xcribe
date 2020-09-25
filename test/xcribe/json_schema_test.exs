defmodule Xcribe.JsonSchemaTest do
  use ExUnit.Case, async: true

  alias Xcribe.JsonSchema

  describe "type_for/1" do
    test "return type for given values" do
      assert JsonSchema.type_for(%{}) == "object"
      assert JsonSchema.type_for([]) == "array"
      assert JsonSchema.type_for("a") == "string"
      assert JsonSchema.type_for(1) == "number"
      assert JsonSchema.type_for(1.0) == "number"
      assert JsonSchema.type_for(true) == "boolean"
    end

    test "return type as string for not know types" do
      assert JsonSchema.type_for(nil) == "string"
      assert JsonSchema.type_for({}) == "string"
      assert JsonSchema.type_for(:ok) == "string"
      assert JsonSchema.type_for(self()) == "string"
    end
  end

  describe "format_for/1" do
    test "return format for given values" do
      assert JsonSchema.format_for(1) == "int32"
      assert JsonSchema.format_for(1.0) == "float"
    end

    test "return empty for not know formats" do
      assert JsonSchema.format_for(true) == ""
      assert JsonSchema.format_for("a") == ""
      assert JsonSchema.format_for(nil) == ""
      assert JsonSchema.format_for({}) == ""
      assert JsonSchema.format_for(:ok) == ""
      assert JsonSchema.format_for(self()) == ""
    end
  end

  describe "schema_for/1" do
    test "schema for map/object whith nested map" do
      map = %{"authentication" => %{"login" => "userlogin"}, "name" => "some name"}

      assert JsonSchema.schema_for(map) == %{
               type: "object",
               properties: %{
                 "authentication" => %{
                   type: "object",
                   properties: %{"login" => %{type: "string", example: "userlogin"}}
                 },
                 "name" => %{type: "string", example: "some name"}
               }
             }
    end

    test "schema for a list/array of strings" do
      data = ["Doug", "Jonny"]

      expected = %{
        type: "array",
        items: %{type: "string", example: "Doug"}
      }

      assert JsonSchema.schema_for(data) == expected
    end

    test "schema for list/array of maps" do
      list = [
        %{"authentication" => %{"login" => "userlogin"}, "name" => "some name"},
        %{"authentication" => %{"login" => "userlogin"}, "name" => "some name"}
      ]

      assert JsonSchema.schema_for(list) == %{
               type: "array",
               items: %{
                 type: "object",
                 properties: %{
                   "name" => %{example: "some name", type: "string"},
                   "authentication" => %{
                     properties: %{"login" => %{example: "userlogin", type: "string"}},
                     type: "object"
                   }
                 }
               }
             }
    end

    test "return a schema for single item as tuple" do
      opts = [title: true, example: false]

      assert JsonSchema.schema_for({"alias", "Jon"}, opts) == %{
               title: "alias",
               type: "string"
             }

      assert JsonSchema.schema_for({"age", 5}, opts) == %{
               title: "age",
               type: "number",
               format: "int32"
             }

      assert JsonSchema.schema_for({"percent", 5.8}, opts) == %{
               title: "percent",
               type: "number",
               format: "float"
             }
    end

    test "given opt title false not return title key" do
      opt = [title: false]

      assert JsonSchema.schema_for({"name", "value"}, opt) == %{type: "string"}
      assert JsonSchema.schema_for({"name", 1}, opt) == %{type: "number", format: "int32"}
      assert JsonSchema.schema_for({"name", 1.2}, opt) == %{type: "number", format: "float"}
    end

    test "given opt example true return the example" do
      opt = [title: false, example: true]

      assert JsonSchema.schema_for({"name", "value"}, opt) == %{
               type: "string",
               example: "value"
             }

      assert JsonSchema.schema_for({"name", 1}, opt) == %{
               type: "number",
               format: "int32",
               example: 1
             }

      assert JsonSchema.schema_for({"name", 1.2}, opt) == %{
               type: "number",
               format: "float",
               example: 1.2
             }

      assert JsonSchema.schema_for({"name", %{"key" => "value"}}, opt) == %{
               type: "object",
               properties: %{"key" => %{type: "string", example: "value"}}
             }

      assert JsonSchema.schema_for({"name", ["value"]}, opt) == %{
               type: "array",
               items: %{type: "string", example: "value"}
             }
    end

    test "schema for a map with an empty list" do
      data = %{"id" => 1, "attributes" => []}

      assert JsonSchema.schema_for(data) == %{
               type: "object",
               properties: %{
                 "attributes" => %{items: %{type: "string"}, type: "array"},
                 "id" => %{example: 1, format: "int32", type: "number"}
               }
             }
    end

    test "schema for stringifiable struct" do
      value = ~D[2020-04-23]
      map = %{"last_login" => value}

      assert JsonSchema.schema_for(map) == %{
               type: "object",
               properties: %{
                 "last_login" => %{type: "string", example: to_string(value)}
               }
             }
    end

    test "schema for map with nested struct that is stringifiable" do
      value = ~D[2020-04-23]
      map = %{"authentication" => %{"last_login" => value}, "name" => "some name"}

      assert JsonSchema.schema_for(map) == %{
               type: "object",
               properties: %{
                 "authentication" => %{
                   type: "object",
                   properties: %{"last_login" => %{type: "string", example: to_string(value)}}
                 },
                 "name" => %{type: "string", example: "some name"}
               }
             }
    end

    defmodule NonStringifiablePerson do
      defstruct [:name, :age]
    end

    test "schema for a struct that is not stringifiable" do
      value = %NonStringifiablePerson{name: "some name", age: 18}
      map = %{"profile" => %{"person" => value}}

      assert JsonSchema.schema_for(map) == %{
               type: "object",
               properties: %{
                 "profile" => %{
                   type: "object",
                   properties: %{
                     "person" => %{
                       type: "object",
                       properties: %{
                         age: %{example: 18, format: "int32", type: "number"},
                         name: %{example: "some name", type: "string"}
                       }
                     }
                   }
                 }
               }
             }
    end
  end
end
