defmodule Xcribe.ConnParserTest do
  use Xcribe.ConnCase, async: true

  alias Xcribe.{ConnParser, Request}

  describe "parse/1" do
    test "extract request data from an index request", %{conn: conn} do
      conn =
        conn
        |> put_req_header("authorization", "token")
        |> get(users_path(conn, :index))

      assert ConnParser.execute(conn) == %Request{
               action: "index",
               controller: "Elixir.Xcribe.UsersController",
               description: "sample request",
               header_params: [{"authorization", "token"}],
               params: %{},
               path: "/users",
               path_params: %{},
               query_params: %{},
               request_body: %{},
               resource: "users",
               resource_group: :api,
               resp_body: "[{\"id\":1,\"name\":\"user 1\"},{\"id\":2,\"name\":\"user 2\"}]",
               resp_headers: [
                 {"content-type", "application/json; charset=utf-8"},
                 {"cache-control", "max-age=0, private, must-revalidate"}
               ],
               status_code: 200,
               verb: "get"
             }
    end

    test "pass a request description", %{conn: conn} do
      conn =
        conn
        |> put_req_header("authorization", "token")
        |> get(users_path(conn, :index))

      description = "get all users"

      assert ConnParser.execute(conn, description) == %Request{
               action: "index",
               controller: "Elixir.Xcribe.UsersController",
               description: description,
               header_params: [{"authorization", "token"}],
               params: %{},
               path: "/users",
               path_params: %{},
               query_params: %{},
               request_body: %{},
               resource: "users",
               resource_group: :api,
               resp_body: "[{\"id\":1,\"name\":\"user 1\"},{\"id\":2,\"name\":\"user 2\"}]",
               resp_headers: [
                 {"content-type", "application/json; charset=utf-8"},
                 {"cache-control", "max-age=0, private, must-revalidate"}
               ],
               status_code: 200,
               verb: "get"
             }
    end

    test "extract request data from a show request", %{conn: conn} do
      conn =
        conn
        |> put_req_header("authorization", "token")
        |> get(users_path(conn, :show, 1))

      assert ConnParser.execute(conn) == %Request{
               action: "show",
               controller: "Elixir.Xcribe.UsersController",
               description: "sample request",
               header_params: [{"authorization", "token"}],
               params: %{"id" => "1"},
               path: "/users/{id}",
               path_params: %{"id" => "1"},
               query_params: %{},
               request_body: %{},
               resource: "users",
               resource_group: :api,
               resp_body: "{\"id\":1,\"name\":\"user 1\"}",
               resp_headers: [
                 {"content-type", "application/json; charset=utf-8"},
                 {"cache-control", "max-age=0, private, must-revalidate"}
               ],
               status_code: 200,
               verb: "get"
             }
    end

    test "extract request data from a create request", %{conn: conn} do
      conn =
        conn
        |> put_req_header("authorization", "token")
        |> post(users_path(conn, :create), %{name: "teste", age: 5})

      assert ConnParser.execute(conn) == %Request{
               action: "create",
               controller: "Elixir.Xcribe.UsersController",
               description: "sample request",
               header_params: [
                 {"authorization", "token"},
                 {"content-type", "multipart/mixed; boundary=plug_conn_test"}
               ],
               params: %{"age" => 5, "name" => "teste"},
               path: "/users",
               path_params: %{},
               query_params: %{},
               request_body: %{"age" => 5, "name" => "teste"},
               resource: "users",
               resource_group: :api,
               resp_body: "{\"age\":5,\"name\":\"teste\"}",
               resp_headers: [
                 {"content-type", "application/json; charset=utf-8"},
                 {"cache-control", "max-age=0, private, must-revalidate"}
               ],
               status_code: 201,
               verb: "post"
             }
    end

    test "extract request data from an update request with put", %{conn: conn} do
      conn =
        conn
        |> put_req_header("authorization", "token")
        |> put(users_path(conn, :update, 1), %{name: "teste", age: 5})

      assert ConnParser.execute(conn) == %Request{
               action: "update",
               controller: "Elixir.Xcribe.UsersController",
               description: "sample request",
               header_params: [
                 {"authorization", "token"},
                 {"content-type", "multipart/mixed; boundary=plug_conn_test"}
               ],
               params: %{"age" => 5, "id" => "1", "name" => "teste"},
               path: "/users/{id}",
               path_params: %{"id" => "1"},
               query_params: %{},
               request_body: %{"age" => 5, "name" => "teste"},
               resource: "users",
               resource_group: :api,
               resp_body: "{\"age\":5,\"name\":\"teste\"}",
               resp_headers: [
                 {"content-type", "application/json; charset=utf-8"},
                 {"cache-control", "max-age=0, private, must-revalidate"}
               ],
               status_code: 200,
               verb: "put"
             }
    end

    test "extract request data from an update request with patch", %{conn: conn} do
      conn =
        conn
        |> put_req_header("authorization", "token")
        |> patch(users_path(conn, :update, 1), %{name: "teste", age: 5})

      assert ConnParser.execute(conn) == %Request{
               action: "update",
               controller: "Elixir.Xcribe.UsersController",
               description: "sample request",
               header_params: [
                 {"authorization", "token"},
                 {"content-type", "multipart/mixed; boundary=plug_conn_test"}
               ],
               params: %{"age" => 5, "id" => "1", "name" => "teste"},
               path: "/users/{id}",
               path_params: %{"id" => "1"},
               query_params: %{},
               request_body: %{"age" => 5, "name" => "teste"},
               resource: "users",
               resource_group: :api,
               resp_body: "{\"age\":5,\"name\":\"teste\"}",
               resp_headers: [
                 {"content-type", "application/json; charset=utf-8"},
                 {"cache-control", "max-age=0, private, must-revalidate"}
               ],
               status_code: 200,
               verb: "patch"
             }
    end

    test "extract request data from a delete request", %{conn: conn} do
      conn =
        conn
        |> put_req_header("authorization", "token")
        |> delete(users_path(conn, :delete, 1))

      assert ConnParser.execute(conn) == %Request{
               action: "delete",
               controller: "Elixir.Xcribe.UsersController",
               description: "sample request",
               header_params: [{"authorization", "token"}],
               params: %{"id" => "1"},
               path: "/users/{id}",
               path_params: %{"id" => "1"},
               query_params: %{},
               request_body: %{},
               resource: "users",
               resource_group: :api,
               resp_body: "",
               resp_headers: [{"cache-control", "max-age=0, private, must-revalidate"}],
               status_code: 204,
               verb: "delete"
             }
    end

    test "extract request data from a nested index request", %{conn: conn} do
      conn =
        conn
        |> put_req_header("authorization", "token")
        |> get(users_posts_path(conn, :index, 1))

      assert ConnParser.execute(conn) == %Request{
               action: "index",
               controller: "Elixir.Xcribe.PostsController",
               description: "sample request",
               header_params: [{"authorization", "token"}],
               params: %{"users_id" => "1"},
               path: "/users/{users_id}/posts",
               path_params: %{"users_id" => "1"},
               query_params: %{},
               request_body: %{},
               resource: "users_posts",
               resource_group: :api,
               resp_body: "[{\"id\":1,\"title\":\"user 1\"},{\"id\":2,\"title\":\"user 2\"}]",
               resp_headers: [
                 {"content-type", "application/json; charset=utf-8"},
                 {"cache-control", "max-age=0, private, must-revalidate"}
               ],
               status_code: 200,
               verb: "get"
             }
    end

    test "extract request data from a nested create request", %{conn: conn} do
      conn =
        conn
        |> put_req_header("authorization", "token")
        |> post(users_posts_path(conn, :create, 1), %{title: "test"})

      assert ConnParser.execute(conn) == %Request{
               action: "create",
               controller: "Elixir.Xcribe.PostsController",
               description: "sample request",
               header_params: [
                 {"authorization", "token"},
                 {"content-type", "multipart/mixed; boundary=plug_conn_test"}
               ],
               params: %{"title" => "test", "users_id" => "1"},
               path: "/users/{users_id}/posts",
               path_params: %{"users_id" => "1"},
               query_params: %{},
               request_body: %{"title" => "test"},
               resource: "users_posts",
               resource_group: :api,
               resp_body: "{\"title\":\"test\",\"users_id\":\"1\"}",
               resp_headers: [
                 {"content-type", "application/json; charset=utf-8"},
                 {"cache-control", "max-age=0, private, must-revalidate"}
               ],
               status_code: 201,
               verb: "post"
             }
    end

    test "extract request data from a nested update request", %{conn: conn} do
      conn =
        conn
        |> put_req_header("authorization", "token")
        |> patch(users_posts_path(conn, :update, 1, 2), %{title: "test"})

      assert ConnParser.execute(conn) == %Request{
               action: "update",
               controller: "Elixir.Xcribe.PostsController",
               description: "sample request",
               header_params: [
                 {"authorization", "token"},
                 {"content-type", "multipart/mixed; boundary=plug_conn_test"}
               ],
               params: %{"id" => "2", "title" => "test", "users_id" => "1"},
               path: "/users/{users_id}/posts/{id}",
               path_params: %{"id" => "2", "users_id" => "1"},
               query_params: %{},
               request_body: %{"title" => "test"},
               resource: "users_posts",
               resource_group: :api,
               resp_body: "{\"title\":\"test\",\"users_id\":\"1\"}",
               resp_headers: [
                 {"content-type", "application/json; charset=utf-8"},
                 {"cache-control", "max-age=0, private, must-revalidate"}
               ],
               status_code: 200,
               verb: "patch"
             }
    end

    test "extract request data from a nested update request with put", %{conn: conn} do
      conn =
        conn
        |> put_req_header("authorization", "token")
        |> put(users_posts_path(conn, :update, 1, 2), %{title: "test"})

      assert ConnParser.execute(conn) == %Request{
               action: "update",
               controller: "Elixir.Xcribe.PostsController",
               description: "sample request",
               header_params: [
                 {"authorization", "token"},
                 {"content-type", "multipart/mixed; boundary=plug_conn_test"}
               ],
               params: %{"id" => "2", "title" => "test", "users_id" => "1"},
               path: "/users/{users_id}/posts/{id}",
               path_params: %{"id" => "2", "users_id" => "1"},
               query_params: %{},
               request_body: %{"title" => "test"},
               resource: "posts",
               resource_group: :api,
               resp_body: "{\"title\":\"test\",\"users_id\":\"1\"}",
               resp_headers: [
                 {"content-type", "application/json; charset=utf-8"},
                 {"cache-control", "max-age=0, private, must-revalidate"}
               ],
               status_code: 200,
               verb: "put"
             }
    end
  end
end
