defmodule Xcribe.ApiBlueprint.APIBTest do
  use ExUnit.Case, async: true

  alias Xcribe.ApiBlueprint
  alias Xcribe.ApiBlueprint.{APIB, Formatter, Multipart}
  alias Xcribe.Support.RequestsGenerator

  setup do
    {:ok,
     %{config: %{specification_source: "test/support/.simple_example.exs", json_library: Jason}}}
  end

  describe "encode/2" do
    test "encode apib struct into apib format", %{config: config} do
      request = RequestsGenerator.users_posts_create()
      struct = ApiBlueprint.apib_struct([request], config)

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
                           "type": "object",
                           "properties": {
                             "title": {
                               "type": "string",
                               "example": "user 1"
                             }
                           }
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
                           "type": "object",
                           "properties": {
                             "title": {
                               "type": "string",
                               "example": "user 1"
                             },
                             "users_id": {
                               "type": "string",
                               "example": "1"
                             }
                           }
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
        |> Map.put(:__meta__, %{config: config})
        |> Formatter.response_object()

      assert APIB.schema(schema, config) == """
                 + Schema

                         {
                           "type": "object",
                           "properties": {
                             "title": {
                               "type": "string",
                               "example": "user 1"
                             },
                             "users_id": {
                               "type": "string",
                               "example": "1"
                             }
                           }
                         }

             """
    end

    test "empty schema", %{config: config} do
      assert APIB.schema(%{}, config) == ""
    end
  end

  describe "parameters/1" do
    test "return parameters" do
      parameters = Formatter.action_parameters(RequestsGenerator.users_posts_create())

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
        |> Map.put(:__meta__, %{config: config})
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
        |> Map.put(:__meta__, %{config: config})
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
                           "type": "object",
                           "properties": {
                             "title": {
                               "type": "string",
                               "example": "user 1"
                             },
                             "users_id": {
                               "type": "string",
                               "example": "1"
                             }
                           }
                         }

             """
    end

    test "when status code is 204", %{config: config} do
      response =
        RequestsGenerator.users_posts_create()
        |> Map.put(:__meta__, %{config: config})
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
      [{name, request}] =
        RequestsGenerator.users_posts_create()
        |> Map.put(:__meta__, %{config: config})
        |> Formatter.request_object()
        |> Map.to_list()

      assert APIB.full_request(name, request, config) == """
             + Request show user post (application/json)
                 + Body

                         {
                           "title": "user 1"
                         }

                 + Schema

                         {
                           "type": "object",
                           "properties": {
                             "title": {
                               "type": "string",
                               "example": "user 1"
                             }
                           }
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
                           "type": "object",
                           "properties": {
                             "title": {
                               "type": "string",
                               "example": "user 1"
                             },
                             "users_id": {
                               "type": "string",
                               "example": "1"
                             }
                           }
                         }

             """
    end
  end

  describe "full_action/3" do
    test "return full action", %{config: config} do
      [{key, action}] =
        RequestsGenerator.users_posts_create()
        |> Map.put(:__meta__, %{config: config})
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
                           "type": "object",
                           "properties": {
                             "title": {
                               "type": "string",
                               "example": "user 1"
                             }
                           }
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
                           "type": "object",
                           "properties": {
                             "title": {
                               "type": "string",
                               "example": "user 1"
                             },
                             "users_id": {
                               "type": "string",
                               "example": "1"
                             }
                           }
                         }

             """
    end

    test "action with query parameters", %{config: config} do
      [{key, action}] =
        RequestsGenerator.users_index()
        |> Map.put(:__meta__, %{config: config})
        |> Map.put(:query_params, %{"limit" => "6"})
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
                           "type": "array",
                           "items": {
                             "type": "object",
                             "properties": {
                               "id": {
                                 "type": "number",
                                 "format": "int32",
                                 "example": 1
                               },
                               "name": {
                                 "type": "string",
                                 "example": "user 1"
                               }
                             }
                           }
                         }

             """
    end
  end

  describe "full_resource/3" do
    test "return full action", %{config: config} do
      [{key, resource}] =
        RequestsGenerator.users_posts_create()
        |> Map.put(:__meta__, %{config: config})
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
                           "type": "object",
                           "properties": {
                             "title": {
                               "type": "string",
                               "example": "user 1"
                             }
                           }
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
                           "type": "object",
                           "properties": {
                             "title": {
                               "type": "string",
                               "example": "user 1"
                             },
                             "users_id": {
                               "type": "string",
                               "example": "1"
                             }
                           }
                         }

             """
    end
  end

  describe "groups/2" do
    test "return groups", %{config: config} do
      request_object =
        RequestsGenerator.users_posts_create()
        |> Map.put(:__meta__, %{config: config})
        |> Formatter.full_request_object()

      requests = Formatter.put_object_into_groups(%{}, request_object)

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
                           "type": "object",
                           "properties": {
                             "title": {
                               "type": "string",
                               "example": "user 1"
                             }
                           }
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
                           "type": "object",
                           "properties": {
                             "title": {
                               "type": "string",
                               "example": "user 1"
                             },
                             "users_id": {
                               "type": "string",
                               "example": "1"
                             }
                           }
                         }

             """
    end
  end
end
