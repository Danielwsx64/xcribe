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
          query_params: %{},
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
          header_params: [{"authorization", "token"}],
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
        }
        | @sample_requests
      ]

      assert Jason.decode!(Swagger.generate_doc(requests)) ==
               Jason.decode!(@sample_swagger_output)
    end
  end
end
