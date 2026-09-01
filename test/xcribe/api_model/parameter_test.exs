defmodule Xcribe.APIModel.ParameterTest do
  use ExUnit.Case, async: true

  alias Xcribe.APIModel.Parameter

  describe "new/3" do
    test "return a required parameter for a path parameter" do
      assert Parameter.new("users_id", :path, "1") == %Parameter{
               name: "users_id",
               location: :path,
               required: true,
               schema: %{type: "string"},
               examples: ["1"]
             }
    end

    test "return an optional parameter for a query parameter" do
      assert Parameter.new("page", :query, "2") == %Parameter{
               name: "page",
               location: :query,
               required: false,
               schema: %{type: "string"},
               examples: ["2"]
             }
    end

    test "return an optional parameter for a header parameter" do
      assert Parameter.new("authorization", :header, "Bearer token") == %Parameter{
               name: "authorization",
               location: :header,
               required: false,
               schema: %{type: "string"},
               examples: ["Bearer token"]
             }
    end

    test "build a schema without an example so merging stays order independent" do
      assert Parameter.new("age", :query, 5).schema == %{type: "number", format: "int32"}
    end

    test "build an object schema for a nested parameter" do
      assert Parameter.new("filter", :query, %{"name" => "user"}) == %Parameter{
               name: "filter",
               location: :query,
               required: false,
               schema: %{type: "object", properties: %{"name" => %{type: "string"}}},
               examples: [%{"name" => "user"}]
             }
    end
  end

  describe "merge/2" do
    test "collect the examples of both parameters sorted and without duplicates" do
      base = Parameter.new("id", :path, "2")
      new = Parameter.new("id", :path, "1")

      assert Parameter.merge(base, new) == %Parameter{
               name: "id",
               location: :path,
               required: true,
               schema: %{type: "string"},
               examples: ["1", "2"]
             }
    end

    test "discard a duplicated example" do
      parameter = Parameter.new("id", :path, "1")

      assert Parameter.merge(parameter, parameter) == parameter
    end

    test "return the same result whatever the merge order" do
      base = Parameter.new("filter", :query, %{"name" => "user"})
      new = Parameter.new("filter", :query, %{"age" => 5})

      assert Parameter.merge(base, new) == Parameter.merge(new, base)
    end

    test "replace the schema when the type of the new parameter differs" do
      base = Parameter.new("id", :query, "1")
      new = Parameter.new("id", :query, 1)

      assert Parameter.merge(base, new).schema == %{type: "number", format: "int32"}
    end
  end

  describe "sort_key/1" do
    test "return the location and the name" do
      assert Parameter.sort_key(Parameter.new("id", :path, "1")) == {:path, "id"}
    end
  end
end
