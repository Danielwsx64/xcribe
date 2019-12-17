defmodule Xcribe.SwaggerTest do
  use ExUnit.Case, async: true
  use Xcribe.RequestsExamples
  use Xcribe.SwaggerExamples

  alias Xcribe.Swagger

  describe "generate_doc/1" do
    test "parse requests do string" do
      requests = [
        %Request{
          action: "create",
          controller: Elixir.Xcribe.UsersController,
          description: "invalid parameters",
          header_params: [
            {"authorization", "token"},
            {"content-type", "multipart/mixed; boundary=plug_conn_test"}
          ],
          params: %{"age" => "5", "name" => 6},
          path: "/users",
          path_params: %{},
          query_params: %{},
          request_body: %{"age" => "5", "name" => 6},
          resource: "users",
          resource_group: :api,
          resp_body: "{\"message\":\"invalid parameters\"}",
          resp_headers: [
            {"content-type", "application/json; charset=utf-8"},
            {"cache-control", "max-age=0, private, must-revalidate"}
          ],
          status_code: 400,
          verb: "post"
        },
        %Request{
          action: "show",
          controller: Elixir.Xcribe.ProtocolsController,
          description: "show the protocol",
          header_params: [{"authorization", "token"}],
          params: %{},
          path: "/server/{server_id}/protocols/{id}",
          path_params: %{"id" => 90, "server_id" => 88},
          query_params: %{"updated_at" => DateTime.utc_now() |> DateTime.to_iso8601()},
          request_body: %{},
          resource: "protocols",
          resource_group: :api,
          resp_body: "[{\"id\":1,\"name\":\"user 1\"},{\"id\":2,\"name\":\"user 2\"}]",
          resp_headers: [
            {"content-type", "application/json"}
          ],
          status_code: 200,
          verb: "get"
        },
        %Request{
          action: "create",
          controller: Elixir.Xcribe.ProtocolsController,
          description: "create the protocol",
          header_params: [],
          params: %{"name" => "zelda", "server_id" => 88, "priority" => 0},
          path: "/server/{server_id}/protocols",
          path_params: %{"server_id" => 88},
          query_params: %{},
          request_body: %{"name" => "zelda", "priority" => 0},
          resource: "protocols",
          resource_group: :api,
          resp_body: "{\"id\":2,\"name\":\"user 2\"}",
          resp_headers: [
            {"content-type", "application/json"}
          ],
          status_code: 201,
          verb: "post"
        },
        %Request{
          action: "index",
          controller: Elixir.Xcribe.ProtocolsController,
          description: "index the protocols",
          header_params: [],
          params: %{},
          path: "/server/{server_id}/protocols",
          path_params: %{},
          query_params: %{},
          request_body: %{},
          resource: "protocols",
          resource_group: :api,
          resp_body: "[{\"id\":2,\"name\":\"user 2\"}]",
          resp_headers: [
            {"content-type", "application/json"}
          ],
          status_code: 200,
          verb: "get"
        }
        | @sample_requests
      ]

      assert Jason.decode!(Swagger.generate_doc(requests)) ==
               Jason.decode!(@sample_swagger_output)
    end

    test "when there is no security schema" do
      requests = [
        %Request{
          action: "index",
          controller: Elixir.Xcribe.ProtocolsController,
          description: "index the protocols",
          header_params: [],
          params: %{},
          path: "/server/{server_id}/protocols",
          path_params: %{},
          query_params: %{},
          request_body: %{},
          resource: "protocols",
          resource_group: :api,
          resp_body: "[{\"id\":2,\"name\":\"user 2\"}]",
          resp_headers: [
            {"content-type", "application/json"}
          ],
          status_code: 200,
          verb: "get"
        }
      ]

      expected = """
      {
        "openapi": "3.0.0",
        "info": {
          "title": "Basic API",
          "version": "0.1.0",
          "description": "The description of the API"
        },
        "paths": {
          "/server/{server_id}/protocols": {
            "get": {
              "summary": "",
              "description": "Application protocols is a awesome feature of our app",
              "responses": {
                "200": {
                  "description": "index the protocols",
                  "content": {
                    "application/json": {
                      "schema": {
                        "type": "array",
                        "items": {
                          "type": "object",
                          "properties": {
                            "id": {
                              "type": "integer",
                              "description": ""
                            },
                            "name": {
                              "type": "string",
                              "description": ""
                            }
                          }
                        }
                      }
                    }
                  },
                  "headers": {
                    "content-type": {
                      "schema": {
                        "type": "string"
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
      """

      assert Jason.decode!(Swagger.generate_doc(requests)) ==
               Jason.decode!(expected)
    end
  end
end
