defmodule Xcribe.APIModel.BodyTest do
  use ExUnit.Case, async: true

  alias Plug.Upload
  alias Xcribe.APIModel.Body

  describe "new/3" do
    test "return a body with the schema and the example of the given map" do
      assert Body.new("application/json", "createUsers", %{"name" => "user 1", "age" => 5}) ==
               %Body{
                 content_type: "application/json",
                 schema_name: "createUsers",
                 schema: %{
                   type: "object",
                   properties: %{
                     "age" => %{type: "number", format: "int32", example: 5},
                     "name" => %{type: "string", example: "user 1"}
                   }
                 },
                 examples: [%{"age" => 5, "name" => "user 1"}]
               }
    end

    test "return an array schema for a list body" do
      assert Body.new("application/json", "Users", [%{"id" => 1}]) == %Body{
               content_type: "application/json",
               schema_name: "Users",
               schema: %{
                 type: "array",
                 items: %{
                   type: "object",
                   properties: %{"id" => %{type: "number", format: "int32", example: 1}}
                 }
               },
               examples: [[%{"id" => 1}]]
             }
    end

    test "return a string schema for a plain text body" do
      assert Body.new("text/plain", "Users", "the body") == %Body{
               content_type: "text/plain",
               schema_name: "Users",
               schema: %{type: "string", example: "the body"},
               examples: ["the body"]
             }
    end

    test "return a binary schema for an upload" do
      upload = %Upload{filename: "file.png", content_type: "image/png", path: "/tmp/file"}

      assert Body.new("multipart/form-data", "createUsers", %{"file" => upload}) == %Body{
               content_type: "multipart/form-data",
               schema_name: "createUsers",
               schema: %{
                 type: "object",
                 properties: %{"file" => %{type: "string", format: "binary"}}
               },
               examples: [%{"file" => upload}]
             }
    end
  end

  describe "merge/2" do
    test "union the properties of both schemas and collect both examples" do
      base = Body.new("application/json", "Users", %{"name" => "user 1"})
      new = Body.new("application/json", "Users", %{"age" => 5})

      assert Body.merge(base, new) == %Body{
               content_type: "application/json",
               schema_name: "Users",
               schema: %{
                 type: "object",
                 properties: %{
                   "age" => %{type: "number", format: "int32", example: 5},
                   "name" => %{type: "string", example: "user 1"}
                 }
               },
               examples: [%{"age" => 5}, %{"name" => "user 1"}]
             }
    end

    test "keep the content type and the schema name of the base body" do
      base = Body.new("application/json", "Users", %{"name" => "user 1"})
      new = Body.new("text/plain", "Other", %{"name" => "user 2"})

      merged = Body.merge(base, new)

      assert merged.content_type == "application/json"
      assert merged.schema_name == "Users"
    end

    test "discard a duplicated example" do
      body = Body.new("application/json", "Users", %{"name" => "user 1"})

      assert Body.merge(body, body) == body
    end
  end

  describe "sort_key/1" do
    test "return the content type" do
      assert Body.sort_key(Body.new("application/json", "Users", %{})) == "application/json"
    end
  end
end
