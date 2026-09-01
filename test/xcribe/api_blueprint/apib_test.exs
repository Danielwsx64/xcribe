defmodule Xcribe.ApiBlueprint.APIBTest do
  use ExUnit.Case, async: true

  alias Xcribe.{ApiBlueprint, APIModel, Specification}
  alias Xcribe.ApiBlueprint.{APIB, Formatter, Multipart}
  alias Xcribe.Support.{RequestsGenerator, Samples}

  setup do
    {:ok,
     %{config: %{specification_source: "test/support/.simple_example.exs", json_library: Jason}}}
  end

  describe "encode/2" do
    test "encode apib struct into apib format", %{config: config} do
      specification = Specification.api_specification(config)
      model = APIModel.build([RequestsGenerator.users_posts_create()], specification, config)
      struct = ApiBlueprint.apib_struct(model, specification)

      assert APIB.encode(struct, config) == """
             FORMAT: 1A
             HOST: http://my-api.com

             # Basic API
             The description of the API

             ## Group Users Posts
             ## Users Posts [/users/{usersId}/posts]
             + Parameters

                 + usersId: `1` (string)

             ### Users Posts create [POST /users/{usersId}/posts]
             + Parameters

                 + usersId: `1` (string)

             + Request show user post (application/json)
                 + Body

                         {
                           "title": "user 1"
                         }

                 + Schema

                         {
                           "properties": {
                             "title": {
                               "example": "user 1",
                               "type": "string"
                             }
                           },
                           "type": "object"
                         }

             + Response 201 (application/json)
                 + Headers

                         cache-control: max-age=0, private, must-revalidate

                 + Body

                         {
                           "title": "user 1",
                           "users_id": "1"
                         }

                 + Schema

                         {
                           "properties": {
                             "title": {
                               "example": "user 1",
                               "type": "string"
                             },
                             "users_id": {
                               "example": "1",
                               "type": "string"
                             }
                           },
                           "type": "object"
                         }

             """
    end
  end

  describe "metadata/1" do
    test "return metadata" do
      map = %{name: "Awesome API", host: "https://api.site.com", description: "The best json API"}

      assert APIB.metadata(map) == """
             FORMAT: 1A
             HOST: https://api.site.com

             # Awesome API
             The best json API

             """
    end
  end

  describe "group/1" do
    test "return group" do
      assert APIB.group("Private API") == "## Group Private API\n"
    end

    test "Empty string as name" do
      assert APIB.group("") == ""
    end
  end

  describe "resource/2" do
    test "return resource" do
      assert APIB.resource("Users", "/users") == "## Users [/users]\n"
    end
  end

  describe "action/2" do
    test "return action" do
      assert APIB.action("Users show", "GET /users/{id}") == "### Users show [GET /users/{id}]\n"
    end
  end

  describe "request/2" do
    test "return request" do
      assert APIB.request("show an user", "application/json") ==
               "+ Request show an user (application/json)\n"
    end

    test "whitout content type" do
      assert APIB.request("show an user", nil) ==
               "+ Request show an user (text/plain)\n"
    end
  end

  describe "response/2" do
    test "return response" do
      assert APIB.response(200, "application/json") == "+ Response 200 (application/json)\n"
    end

    test "without content type" do
      assert APIB.response(200, nil) == "+ Response 200 (text/plain)\n"
    end
  end

  describe "headers/1" do
    test "return headers" do
      headers = %{"content_type" => "application/json", "token" => "jwt Token"}

      assert APIB.headers(headers) == """
                 + Headers

                         content_type: application/json
                         token: jwt Token

             """
    end

    test "return empty when does not has header" do
      assert APIB.headers(%{}) == ""
    end
  end

  describe "schema/2" do
    test "return schema", %{config: config} do
      %{schema: schema} =
        RequestsGenerator.users_posts_create()
        |> Samples.APIModel.example()
        |> Formatter.response_object()

      assert APIB.schema(schema, config) == """
                 + Schema

                         {
                           "properties": {
                             "title": {
                               "example": "user 1",
                               "type": "string"
                             },
                             "users_id": {
                               "example": "1",
                               "type": "string"
                             }
                           },
                           "type": "object"
                         }

             """
    end

    test "empty schema", %{config: config} do
      assert APIB.schema(%{}, config) == ""
    end
  end

  describe "parameters/1" do
    test "return parameters" do
      operation = Samples.APIModel.operation(RequestsGenerator.users_posts_create())
      parameters = Formatter.action_parameters(operation)

      assert APIB.parameters(parameters) == """
             + Parameters

                 + usersId: `1` (string)

             """
    end

    test "parameters with array" do
      parameters = %{
        "financialAccounts" => %{
          items: %{example: "12", type: "string"},
          type: "array"
        }
      }

      assert APIB.parameters(parameters) ==
               "+ Parameters\n\n    + financialAccounts: `12` (array(string))\n\n"
    end
  end

  describe "body/2" do
    test "return body", %{config: config} do
      %{body: body} =
        RequestsGenerator.users_posts_create()
        |> Samples.APIModel.example()
        |> Formatter.response_object()

      assert APIB.body(body, config) == """
                 + Body

                         {
                           "title": "user 1",
                           "users_id": "1"
                         }

             """
    end

    test "empty body", %{config: config} do
      assert APIB.body(%{}, config) == ""
    end

    test "multipart body", %{config: config} do
      body = %Multipart{
        boundary: "---boundary",
        parts: [
          %{content_type: "text/plain", name: "user_id", value: "123"},
          %{
            content_type: "image/png",
            filename: "screenshot.png",
            name: "file",
            value: "image-binary"
          }
        ]
      }

      expected = """
          + Body



                  ---boundary
                  Content-Disposition: form-data; name="user_id"
                  Content-Type: text/plain

                  123

                  ---boundary
                  Content-Disposition: form-data; name="file"
                  Content-Type: image/png

                  image-binary

      """

      assert APIB.body(body, config) == expected
    end
  end

  describe "full_response/2" do
    test "return full response", %{config: config} do
      response =
        RequestsGenerator.users_posts_create()
        |> Samples.APIModel.example()
        |> Formatter.response_object()

      assert APIB.full_response(response, config) == """
             + Response 201 (application/json)
                 + Headers

                         cache-control: max-age=0, private, must-revalidate

                 + Body

                         {
                           "title": "user 1",
                           "users_id": "1"
                         }

                 + Schema

                         {
                           "properties": {
                             "title": {
                               "example": "user 1",
                               "type": "string"
                             },
                             "users_id": {
                               "example": "1",
                               "type": "string"
                             }
                           },
                           "type": "object"
                         }

             """
    end

    test "when status code is 204", %{config: config} do
      response =
        RequestsGenerator.users_posts_create()
        |> Samples.APIModel.example()
        |> Formatter.response_object()

      assert APIB.full_response(%{response | status: 204}, config) == """
             + Response 204 (application/json)
                 + Headers

                         cache-control: max-age=0, private, must-revalidate

             """
    end
  end

  describe "full_request/2" do
    test "return full request", %{config: config} do
      example = Samples.APIModel.example(RequestsGenerator.users_posts_create())

      assert APIB.full_request(example.description, Formatter.request_object(example), config) ==
               """
               + Request show user post (application/json)
                   + Body

                           {
                             "title": "user 1"
                           }

                   + Schema

                           {
                             "properties": {
                               "title": {
                                 "example": "user 1",
                                 "type": "string"
                               }
                             },
                             "type": "object"
                           }

               + Response 201 (application/json)
                   + Headers

                           cache-control: max-age=0, private, must-revalidate

                   + Body

                           {
                             "title": "user 1",
                             "users_id": "1"
                           }

                   + Schema

                           {
                             "properties": {
                               "title": {
                                 "example": "user 1",
                                 "type": "string"
                               },
                               "users_id": {
                                 "example": "1",
                                 "type": "string"
                               }
                             },
                             "type": "object"
                           }

               """
    end
  end

  describe "full_action/3" do
    test "return full action", %{config: config} do
      [{key, action}] =
        RequestsGenerator.users_posts_create()
        |> Samples.APIModel.operation()
        |> Formatter.action_object()
        |> Map.to_list()

      assert APIB.full_action(key, action, config) == """
             ### Users Posts create [POST /users/{usersId}/posts]
             + Parameters

                 + usersId: `1` (string)

             + Request show user post (application/json)
                 + Body

                         {
                           "title": "user 1"
                         }

                 + Schema

                         {
                           "properties": {
                             "title": {
                               "example": "user 1",
                               "type": "string"
                             }
                           },
                           "type": "object"
                         }

             + Response 201 (application/json)
                 + Headers

                         cache-control: max-age=0, private, must-revalidate

                 + Body

                         {
                           "title": "user 1",
                           "users_id": "1"
                         }

                 + Schema

                         {
                           "properties": {
                             "title": {
                               "example": "user 1",
                               "type": "string"
                             },
                             "users_id": {
                               "example": "1",
                               "type": "string"
                             }
                           },
                           "type": "object"
                         }

             """
    end

    test "action with query parameters", %{config: config} do
      [{key, action}] =
        RequestsGenerator.users_index()
        |> Map.put(:query_params, %{"limit" => "6"})
        |> Samples.APIModel.operation()
        |> Formatter.action_object()
        |> Map.to_list()

      assert APIB.full_action(key, action, config) == """
             ### Users index [GET /users{?limit}]
             + Parameters

                 + limit: `6` (string)

             + Request show users (application/json)
             + Response 200 (application/json)
                 + Headers

                         cache-control: max-age=0, private, must-revalidate

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

                 + Schema

                         {
                           "items": {
                             "properties": {
                               "id": {
                                 "example": 1,
                                 "format": "int32",
                                 "type": "number"
                               },
                               "name": {
                                 "example": "user 1",
                                 "type": "string"
                               }
                             },
                             "type": "object"
                           },
                           "type": "array"
                         }

             """
    end
  end

  describe "full_resource/3" do
    test "return full action", %{config: config} do
      [{key, resource}] =
        RequestsGenerator.users_posts_create()
        |> Samples.APIModel.operation()
        |> Formatter.resource_object()
        |> Map.to_list()

      assert APIB.full_resource(key, resource, config) == """
             ## Users Posts [/users/{usersId}/posts]
             + Parameters

                 + usersId: `1` (string)

             ### Users Posts create [POST /users/{usersId}/posts]
             + Parameters

                 + usersId: `1` (string)

             + Request show user post (application/json)
                 + Body

                         {
                           "title": "user 1"
                         }

                 + Schema

                         {
                           "properties": {
                             "title": {
                               "example": "user 1",
                               "type": "string"
                             }
                           },
                           "type": "object"
                         }

             + Response 201 (application/json)
                 + Headers

                         cache-control: max-age=0, private, must-revalidate

                 + Body

                         {
                           "title": "user 1",
                           "users_id": "1"
                         }

                 + Schema

                         {
                           "properties": {
                             "title": {
                               "example": "user 1",
                               "type": "string"
                             },
                             "users_id": {
                               "example": "1",
                               "type": "string"
                             }
                           },
                           "type": "object"
                         }

             """
    end
  end

  describe "groups/2" do
    test "emit groups in name order past the flatmap threshold" do
      # Over 32 keys a map stops iterating in term order, so the encoder has to sort explicitly or
      # adding one group reshuffles the whole document.
      groups =
        Map.new(1..40, fn index ->
          {"Group #{String.pad_leading(to_string(index), 2, "0")}", %{resources: %{}}}
        end)

      output = APIB.groups(groups, %{json_library: Jason})

      names = Regex.scan(~r/## Group (.+)\n/, output) |> Enum.map(fn [_, name] -> name end)

      assert names == Enum.sort(names)
      assert length(names) == 40
    end

    test "return groups", %{config: config} do
      operation = Samples.APIModel.operation(RequestsGenerator.users_posts_create())
      requests = Formatter.put_operation_into_groups(%{}, operation)

      assert APIB.groups(requests, config) == """
             ## Group Users Posts
             ## Users Posts [/users/{usersId}/posts]
             + Parameters

                 + usersId: `1` (string)

             ### Users Posts create [POST /users/{usersId}/posts]
             + Parameters

                 + usersId: `1` (string)

             + Request show user post (application/json)
                 + Body

                         {
                           "title": "user 1"
                         }

                 + Schema

                         {
                           "properties": {
                             "title": {
                               "example": "user 1",
                               "type": "string"
                             }
                           },
                           "type": "object"
                         }

             + Response 201 (application/json)
                 + Headers

                         cache-control: max-age=0, private, must-revalidate

                 + Body

                         {
                           "title": "user 1",
                           "users_id": "1"
                         }

                 + Schema

                         {
                           "properties": {
                             "title": {
                               "example": "user 1",
                               "type": "string"
                             },
                             "users_id": {
                               "example": "1",
                               "type": "string"
                             }
                           },
                           "type": "object"
                         }

             """
    end
  end
end
