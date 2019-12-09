defmodule Xcribe.SwaggerTest do
  use ExUnit.Case, async: true
  use Xcribe.RequestsExamples
  use Xcribe.SwaggerExamples

  alias Xcribe.Swagger

  describe "generate_doc/1" do
    test "parse requests do string" do
      requests = [
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
