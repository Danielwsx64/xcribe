defmodule Xcribe.ApiBlueprint.APIBTest do
  use ExUnit.Case, async: false

  alias Xcribe.ApiBlueprint
  alias Xcribe.ApiBlueprint.{APIB, Formatter}
  alias Xcribe.Support.RequestsGenerator

  setup do
    Application.put_env(:xcribe, :information_source, Xcribe.Support.Information)

    on_exit(fn ->
      Application.delete_env(:xcribe, :information_source)
    end)
  end

  describe "encode/1" do
    test "encode apib struct into apib format" do
      request = RequestsGenerator.users_posts_create()
      struct = ApiBlueprint.apib_struct([request])

      assert APIB.encode(struct) == """
             FORMAT: 1A
             HOST: http://my-api.com

             # Basic API
             The description of the API

             ## Group Api
             ## Users Posts [/users/{usersId}/posts]
             + Parameters

                 + usersId: `1` (string)

             ### Users Posts create [POST /users/{usersId}/posts]
             + Parameters

                 + usersId: `1` (string)

             + Request show user post (application/json)
                 + Body

                         {
                           "title": "test"
                         }

                 + Schema

                         {
                           "properties": {
                             "title": {
                               "example": "test",
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
                           "title": "test",
                           "users_id": "1"
                         }

                 + Schema

                         {
                           "properties": {
                             "title": {
                               "example": "test",
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

    test "don't print group section when resource group has no name" do
      request = RequestsGenerator.no_pipe_users_index()
      struct = ApiBlueprint.apib_struct([request])

      refute APIB.encode(struct) =~ "# Group"
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

  describe "schema/1" do
    test "return schema" do
      %{schema: schema} = Formatter.response_object(RequestsGenerator.users_posts_create())

      assert APIB.schema(schema) == """
                 + Schema

                         {
                           "properties": {
                             "title": {
                               "example": "test",
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

    test "empty schema" do
      assert APIB.schema(%{}) == ""
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

  describe "body/1" do
    test "return body" do
      %{body: body} = Formatter.response_object(RequestsGenerator.users_posts_create())

      assert APIB.body(body) == """
                 + Body

                         {
                           "title": "test",
                           "users_id": "1"
                         }

             """
    end

    test "empty body" do
      assert APIB.body(%{}) == ""
    end
  end

  describe "full_response/1" do
    test "return full response" do
      response = Formatter.response_object(RequestsGenerator.users_posts_create())

      assert APIB.full_response(response) == """
             + Response 201 (application/json)
                 + Headers

                         cache-control: max-age=0, private, must-revalidate

                 + Body

                         {
                           "title": "test",
                           "users_id": "1"
                         }

                 + Schema

                         {
                           "properties": {
                             "title": {
                               "example": "test",
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

    test "when status code is 204" do
      response = Formatter.response_object(RequestsGenerator.users_posts_create())

      assert APIB.full_response(%{response | status: 204}) == """
             + Response 204 (application/json)
                 + Headers

                         cache-control: max-age=0, private, must-revalidate

             """
    end
  end

  describe "full_request/1" do
    test "return full request" do
      [{name, request}] =
        RequestsGenerator.users_posts_create()
        |> Formatter.request_object()
        |> Map.to_list()

      assert APIB.full_request(name, request) == """
             + Request show user post (application/json)
                 + Body

                         {
                           "title": "test"
                         }

                 + Schema

                         {
                           "properties": {
                             "title": {
                               "example": "test",
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
                           "title": "test",
                           "users_id": "1"
                         }

                 + Schema

                         {
                           "properties": {
                             "title": {
                               "example": "test",
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

  describe "full_action/2" do
    test "return full action" do
      [{key, action}] =
        RequestsGenerator.users_posts_create()
        |> Formatter.action_object()
        |> Map.to_list()

      assert APIB.full_action(key, action) == """
             ### Users Posts create [POST /users/{usersId}/posts]
             + Parameters

                 + usersId: `1` (string)

             + Request show user post (application/json)
                 + Body

                         {
                           "title": "test"
                         }

                 + Schema

                         {
                           "properties": {
                             "title": {
                               "example": "test",
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
                           "title": "test",
                           "users_id": "1"
                         }

                 + Schema

                         {
                           "properties": {
                             "title": {
                               "example": "test",
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

    test "action with query parameters" do
      [{key, action}] =
        RequestsGenerator.users_index()
        |> Map.put(:query_params, %{"limit" => "6"})
        |> Formatter.action_object()
        |> Map.to_list()

      assert APIB.full_action(key, action) == """
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

  describe "full_resource/2" do
    test "return full action" do
      [{key, resource}] =
        RequestsGenerator.users_posts_create()
        |> Formatter.resource_object()
        |> Map.to_list()

      assert APIB.full_resource(key, resource) == """
             ## Users Posts [/users/{usersId}/posts]
             + Parameters

                 + usersId: `1` (string)

             ### Users Posts create [POST /users/{usersId}/posts]
             + Parameters

                 + usersId: `1` (string)

             + Request show user post (application/json)
                 + Body

                         {
                           "title": "test"
                         }

                 + Schema

                         {
                           "properties": {
                             "title": {
                               "example": "test",
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
                           "title": "test",
                           "users_id": "1"
                         }

                 + Schema

                         {
                           "properties": {
                             "title": {
                               "example": "test",
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

  describe "groups/1" do
    test "return groups" do
      request = Formatter.full_request_object(RequestsGenerator.users_posts_create())

      assert APIB.groups(request) == """
             ## Group Api
             ## Users Posts [/users/{usersId}/posts]
             + Parameters

                 + usersId: `1` (string)

             ### Users Posts create [POST /users/{usersId}/posts]
             + Parameters

                 + usersId: `1` (string)

             + Request show user post (application/json)
                 + Body

                         {
                           "title": "test"
                         }

                 + Schema

                         {
                           "properties": {
                             "title": {
                               "example": "test",
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
                           "title": "test",
                           "users_id": "1"
                         }

                 + Schema

                         {
                           "properties": {
                             "title": {
                               "example": "test",
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
