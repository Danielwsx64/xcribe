defmodule Xcribe.ApiBlueprint.FormatterTest do
  use ExUnit.Case, async: true

  alias Xcribe.ApiBlueprint.Formatter
  alias Xcribe.Request

  describe "resource_group/1" do
    test "return formatted resource group" do
      struct = %Request{resource_group: :api}

      assert Formatter.resource_group(struct) == "## Group API\n"
    end

    test "remove underlines" do
      struct = %Request{resource_group: :awesome_api}

      assert Formatter.resource_group(struct) == "## Group AWESOME API\n"
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

    test "resource with underline" do
      struct = %Request{resource: "users_posts", path: "/users/{id}/posts/{post_id}"}

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
               "### Users Posts update [PUT /users/{id}/posts/{post_id}/]\n"
    end

    test "when there is underline" do
      struct = %Request{resource: "users_posts", path: "/users", action: "new_index", verb: "get"}

      assert Formatter.resource_action(struct) == "### Users Posts new index [GET /users/]\n"
    end
  end

  describe "request_description/1" do
    test "return formatted request description" do
      struct = %Request{description: "create user with token"}

      assert Formatter.request_description(struct) ==
               "+ Request create user with token (text/plain)\n"
    end

    test "clean description" do
      struct = %Request{description: "POST /api/boletos [ create  ] add a boleto"}

      assert Formatter.request_description(struct) ==
               "+ Request POST api boletos create add a boleto (text/plain)\n"
    end

    test "when content type is set" do
      struct = %Request{
        description: "create user with token",
        header_params: [
          {"content-type", "application/json; charset=utf-8"},
          {"cache-control", "max-age=0, private, must-revalidate"}
        ]
      }

      assert Formatter.request_description(struct) ==
               "+ Request create user with token (application/json; charset=utf-8)\n"
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

                         authorization: token
             """
    end

    test "just content type" do
      struct = %Request{
        header_params: [
          {"content-type", "multipart/mixed; boundary=plug_conn_test"}
        ]
      }

      assert Formatter.request_headers(struct) == ""
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

      assert Formatter.response_description(struct) == "+ Response 201 (text/plain)\n"
    end

    test "when has content type header" do
      struct = %Request{
        status_code: 201,
        resp_headers: [
          {"content-type", "multipart/mixed"}
        ]
      }

      assert Formatter.response_description(struct) == "+ Response 201 (multipart/mixed)\n"
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

                         authorization: token
             """
    end

    test "just content header" do
      struct = %Request{
        resp_headers: [
          {"content-type", "multipart/mixed; boundary=plug_conn_test"}
        ]
      }

      assert Formatter.response_headers(struct) == ""
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
             + Request create an user (multipart/mixed; boundary=plug_conn_test)
                 + Headers

                         authorization: token
                 + Body

                         {
                           "age": 5,
                           "name": "teste"
                         }

             + Response 201 (application/json; charset=utf-8)
                 + Headers

                         cache-control: max-age=0, private, must-revalidate
                 + Body

                         {
                           "age": 5,
                           "name": "teste"
                         }
             """
    end
  end
end
