defmodule Xcribe.SwaggerTest do
  use ExUnit.Case, async: true

  alias Xcribe.Swagger
  alias Xcribe.Structs.{SwaggerData, ParsedRequest}

  describe "add_request/2" do
    test "add get request" do
      request = %ParsedRequest{
        action: "index",
        header_params: [{"authorization", "token"}],
        params: %{},
        path: "/users",
        path_params: %{},
        query_params: %{},
        request_body: %{},
        resource: "users",
        resource_group: :api,
        resp_body: "[{\"id\":1,\"name\":\"user 1\"},{\"id\":2,\"name\":\"user 2\"}]",
        resp_headers: [
          {"content-type", "application/json; charset=utf-8"},
          {"cache-control", "max-age=0, private, must-revalidate"}
        ],
        status_code: 200,
        verb: "get"
      }

      assert Swagger.add_request(%SwaggerData{}, request) == %SwaggerData{
               paths: %{
                 "/users" => %{
                   "get" => %{
                     "summary" => "Users index",
                     "operationId" => "usersIndex",
                     "produces" => [
                       "application/json"
                     ]
                   }
                 }
               }
             }
    end
  end
end
