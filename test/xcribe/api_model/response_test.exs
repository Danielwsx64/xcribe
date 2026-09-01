defmodule Xcribe.APIModel.ResponseTest do
  use ExUnit.Case, async: true

  alias Xcribe.APIModel.{Body, Parameter, Response}

  describe "new/3" do
    test "return a response with the headers and the content sorted" do
      headers = [Parameter.new("content-type", :header, "application/json")]
      content = [Body.new("application/json", "Users", %{"name" => "user 1"})]

      assert Response.new(200, headers, content) == %Response{
               status: 200,
               headers: headers,
               content: content
             }
    end

    test "sort the headers by name" do
      headers = [
        Parameter.new("content-type", :header, "application/json"),
        Parameter.new("cache-control", :header, "private")
      ]

      assert Response.new(200, headers, []).headers == Enum.reverse(headers)
    end

    test "return a response without content" do
      assert Response.new(204, [], []) == %Response{status: 204, headers: [], content: []}
    end
  end

  describe "merge/2" do
    test "union the headers of both responses" do
      base = Response.new(200, [Parameter.new("etag", :header, "1")], [])
      new = Response.new(200, [Parameter.new("cache-control", :header, "private")], [])

      assert Response.merge(base, new).headers == [
               Parameter.new("cache-control", :header, "private"),
               Parameter.new("etag", :header, "1")
             ]
    end

    test "merge the content of the same content type" do
      base = Response.new(200, [], [Body.new("application/json", "Users", %{"name" => "u"})])
      new = Response.new(200, [], [Body.new("application/json", "Users", %{"age" => 5})])

      assert Response.merge(base, new).content == [
               Body.merge(
                 Body.new("application/json", "Users", %{"name" => "u"}),
                 Body.new("application/json", "Users", %{"age" => 5})
               )
             ]
    end

    test "keep both bodies when the content types differ" do
      base = Response.new(200, [], [Body.new("text/plain", "Users", "text")])
      new = Response.new(200, [], [Body.new("application/json", "Users", %{})])

      assert Enum.map(Response.merge(base, new).content, & &1.content_type) == [
               "application/json",
               "text/plain"
             ]
    end
  end

  describe "sort_key/1" do
    test "return the status" do
      assert Response.sort_key(Response.new(204, [], [])) == 204
    end
  end
end
