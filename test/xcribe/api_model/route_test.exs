defmodule Xcribe.APIModel.RouteTest do
  use ExUnit.Case, async: true

  alias Xcribe.APIModel.{Operation, Route}

  alias Xcribe.Support.RequestsGenerator

  @config %{json_library: Jason}

  describe "from_request/2" do
    test "return a route holding the operation of the given request" do
      request = RequestsGenerator.users_create()

      assert Route.from_request(request, @config) == %Route{
               path: "/users",
               operations: [Operation.from_request(request, @config)]
             }
    end
  end

  describe "merge/2" do
    test "keep one operation per verb sorted by verb" do
      base = Route.from_request(RequestsGenerator.users_create(), @config)
      new = Route.from_request(RequestsGenerator.users_index(), @config)

      assert Route.merge(base, new) |> Map.get(:operations) |> Enum.map(& &1.verb) == [
               "get",
               "post"
             ]
    end

    test "merge the operations sharing a verb" do
      route = Route.from_request(RequestsGenerator.users_show(), @config)

      assert [operation] = Route.merge(route, route).operations
      assert length(operation.examples) == 2
    end

    test "keep the path of the base route" do
      route = Route.from_request(RequestsGenerator.users_show(), @config)

      assert Route.merge(route, route).path == "/users/{id}"
    end
  end

  describe "sort_key/1" do
    test "return the path" do
      route = Route.from_request(RequestsGenerator.users_create(), @config)

      assert Route.sort_key(route) == "/users"
    end
  end
end
