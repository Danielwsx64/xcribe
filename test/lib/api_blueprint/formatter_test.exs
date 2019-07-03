defmodule Xcribe.ApiBlueprint.FormatterTest do
  use ExUnit.Case, async: true

  alias Xcribe.ApiBlueprint.Formatter
  alias Xcribe.Request

  describe "resource_group/1" do
    test "return formatted resource group" do
      struct = %Request{resource_group: :api}

      assert Formatter.resource_group(struct) == "## API\n"
    end
  end

  describe "resource/1" do
    test "return formatted resource" do
      struct = %Request{resource: "users", path: "/users"}

      assert Formatter.resource(struct) == "## Users [/users/]\n"
    end

    test "when path ends with forward slash" do
      struct = %Request{resource: "users", path: "/users/"}

      assert Formatter.resource(struct) == "## Users [/users/]\n"
    end

    test "when there is an arg in the path's end" do
      struct = %Request{resource: "users posts", path: "/users/{id}/posts/{post_id}"}

      assert Formatter.resource(struct) == "## Users Posts [/users/{id}/posts/]\n"
    end
  end

  describe "resource_action/1" do
    test "return formatted resource action" do
      struct = %Request{resource: "users", path: "/users", action: "index", verb: "get"}

      assert Formatter.resource_action(struct) == "### Users index [GET /users/]\n"
    end

    test "when there is an arg in the path's end" do
      struct = %Request{
        resource: "users posts",
        path: "/users/{id}/posts/{post_id}",
        action: "update",
        verb: "put"
      }

      assert Formatter.resource_action(struct) ==
               "### Users Posts update [PUT /users/{id}/posts/]\n"
    end
  end

  describe "request_description/1" do
    test "return formatted request description" do
      struct = %Request{description: "create user with token"}

      assert Formatter.request_description(struct) == "+ create user with token\n"
    end
  end

  describe "request_headers/1" do
    test "return formatted request headers" do
      struct = %Request{
        header_params: [
          {"authorization", "token"},
          {"content-type", "multipart/mixed; boundary=plug_conn_test"}
        ]
      }

      assert Formatter.request_headers(struct) == """
                 + Headers

                         content-type: multipart/mixed; boundary=plug_conn_test
                         authorization: token
             """
    end

    test "return empty string when no headers" do
      struct = %Request{
        header_params: []
      }

      assert Formatter.request_headers(struct) == ""
    end
  end

  describe "request_body/1" do
    test "return formatted request body" do
      struct = %Request{
        request_body: %{"age" => 5, "name" => "teste"}
      }

      assert Formatter.request_body(struct) == """
                 + Body

                         {
                           "age": 5,
                           "name": "teste"
                         }
             """
    end

    test "return empty string when no body" do
      struct = %Request{
        request_body: %{}
      }

      assert Formatter.request_body(struct) == ""
    end
  end

  describe "response_description/1" do
    test "return formatted response description" do
      struct = %Request{
        status_code: 201
      }

      assert Formatter.response_description(struct) == "+ Response 201\n"
    end
  end

  describe "response_headers/1" do
    test "return formatted request headers" do
      struct = %Request{
        resp_headers: [
          {"authorization", "token"},
          {"content-type", "multipart/mixed; boundary=plug_conn_test"}
        ]
      }

      assert Formatter.response_headers(struct) == """
                 + Headers

                         content-type: multipart/mixed; boundary=plug_conn_test
                         authorization: token
             """
    end

    test "return empty string when no headers" do
      struct = %Request{
        resp_headers: []
      }

      assert Formatter.response_headers(struct) == ""
    end
  end

  describe "response_body/1" do
    test "return formatted request body" do
      struct = %Request{
        resp_body: "{\"age\":5,\"name\":\"teste\"}"
      }

      assert Formatter.response_body(struct) == """
                 + Body

                         {
                           "age": 5,
                           "name": "teste"
                         }
             """
    end

    test "return empty string when no body" do
      struct = %Request{
        resp_body: %{}
      }

      assert Formatter.response_body(struct) == ""
    end
  end

  describe "full_request/1" do
    test "return full request" do
      struct = %Request{
        description: "create an user",
        header_params: [
          {"authorization", "token"},
          {"content-type", "multipart/mixed; boundary=plug_conn_test"}
        ],
        params: %{"age" => 5, "name" => "teste"},
        request_body: %{"age" => 5, "name" => "teste"},
        resp_body: "{\"age\":5,\"name\":\"teste\"}",
        resp_headers: [
          {"content-type", "application/json; charset=utf-8"},
          {"cache-control", "max-age=0, private, must-revalidate"}
        ],
        status_code: 201
      }

      assert Formatter.full_request(struct) == """
             + create an user
                 + Headers

                         content-type: multipart/mixed; boundary=plug_conn_test
                         authorization: token
                 + Body

                         {
                           "age": 5,
                           "name": "teste"
                         }

             + Response 201
                 + Headers

                         cache-control: max-age=0, private, must-revalidate
                         content-type: application/json; charset=utf-8
                 + Body

                         {
                           "age": 5,
                           "name": "teste"
                         }
             """
    end
  end
end
