defmodule Xcribe.ApiBlueprintTest do
  use ExUnit.Case, async: true
  use Xcribe.RequestsExamples
  use Xcribe.ApiBlueprintExamples

  alias Xcribe.ApiBlueprint

  describe "group_requests/1" do
    test "group requests" do
      assert ApiBlueprint.group_requests(@sample_requests) == @grouped_sample_requests
    end
  end

  describe "grouped_requests_to_string/1" do
    test "parse routes to string" do
      assert ApiBlueprint.grouped_requests_to_string(@grouped_sample_requests) ==
               @sample_requests_as_string
    end
  end

  describe "generate_doc/1" do
    test "parse requests to string" do
      assert ApiBlueprint.generate_doc(@sample_requests) == @sample_requests_as_string
    end

    test "when list is empty just the metadata" do
      assert ApiBlueprint.generate_doc([]) ==
               "FORMAT: 1A\nHOST: http://my-api.com\n\n# Basic API\nThe description of the API\n\n"
    end

    test "when controller has information defined" do
      requests = [
        %Request{
          action: "show",
          controller: Elixir.Xcribe.ProtocolsController,
          description: "show the protocol",
          header_params: [{"authorization", "token"}],
          params: %{},
          path: "server/{server_id}/protocols/{id}",
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
          header_params: [{"authorization", "token"}, {"content-type", "application/json"}],
          params: %{"name" => "zelda", "server_id" => 88, "priority" => 0},
          path: "server/{server_id}/protocols",
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
      ]

      # assert ApiBlueprint.generate_doc(requests) == ""

      assert ApiBlueprint.generate_doc(requests) == """
             FORMAT: 1A
             HOST: http://my-api.com

             # Basic API
             The description of the API

             ## Group API
             ## Protocols [server/{serverId}/protocols/]
             Application protocols is a awesome feature of our app

             + Parameters

                 + serverId: `88` (required, number) - The id number of the server

             ### Protocols create [POST server/{serverId}/protocols/]
             + Request create the protocol (application/json)
                 + Headers

                         authorization: token

                 + Attributes

                     + name: `zelda` (string) - The protocol full name
                     + priority: `0` (number) - the priority of the protocol. It could be 0 or 1

                 + Body

                         {
                           "name": "zelda",
                           "priority": 0
                         }
             + Response 201 (application/json)
                 + Body

                         {
                           "id": 2,
                           "name": "user 2"
                         }
             ### Protocols show [GET server/{serverId}/protocols/{id}/]
             You can show a protocol with show action

             + Parameters

                 + id: `90` (required, number) - The id

             + Request show the protocol (text/plain)
                 + Headers

                         authorization: token

             + Response 200 (application/json)
                 + Body

                         [
                           {
                             "id": 1,
                             "name": "user 1"
                           },
                           {
                             "id": 2,
                             "name": "user 2"
                           }
                         ]
             """
    end
  end
end
