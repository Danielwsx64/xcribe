defmodule Xcribe.ApiBlueprintTest do
  use ExUnit.Case, async: true
  use Xcribe.RequestsExamples

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

    test "when list is empty" do
      assert ApiBlueprint.generate_doc([]) == ""
    end

    test "when controller has protocol" do
      requests = [
        %Request{
          action: "index",
          controller: Elixir.Xcribe.ProtocolsController,
          description: "index of protocols",
          header_params: [{"authorization", "token"}],
          params: %{},
          path: "/protocols",
          path_params: %{},
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
        }
      ]

      assert ApiBlueprint.generate_doc(requests) == """
             ## Group API
             ## Protocols [/protocols/]
             Application protocols is a awesome feature of our app

             ### Protocols index [GET /protocols/]
             You can get all protocols with index action

             + Request index of protocols (text/plain)
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
