defmodule Xcribe.ConnParserTest do
  use Xcribe.ConnCase, async: true

  alias Plug.Conn
  alias Xcribe.{ConnParser, Request, Request.Error}

  setup do
    Application.put_env(:xcribe, :information_source, Xcribe.Support.Information)

    :ok
  end

  describe "execute/2" do
    test "extract request data from an index request", %{conn: conn} do
      conn =
        conn
        |> put_req_header("authorization", "token")
        |> get(users_path(conn, :index))

      assert ConnParser.execute(conn) == %Request{
               action: "index",
               controller: Elixir.Xcribe.UsersController,
               description: "",
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
               controller: Elixir.Xcribe.UsersController,
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

    test "route out of standard REST", %{conn: conn} do
      conn =
        conn
        |> put_req_header("authorization", "token")
        |> post(users_cancel_path(conn, :cancel, 1))

      assert ConnParser.execute(conn) == %Xcribe.Request{
               action: "cancel",
               controller: Elixir.Xcribe.UsersController,
               description: "",
               header_params: [{"authorization", "token"}],
               params: %{"users_id" => "1"},
               path: "/users/{users_id}/cancel",
               path_params: %{"users_id" => "1"},
               query_params: %{},
               request_body: %{},
               resource: "users_cancel",
               resource_group: :api,
               resp_body: "",
               resp_headers: [
                 {"cache-control", "max-age=0, private, must-revalidate"}
               ],
               status_code: 204,
               verb: "post"
             }
    end

    test "extract request data from a show request", %{conn: conn} do
      conn =
        conn
        |> put_req_header("authorization", "token")
        |> get(users_path(conn, :show, 1))

      assert ConnParser.execute(conn) == %Request{
               action: "show",
               controller: Elixir.Xcribe.UsersController,
               description: "",
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
               controller: Elixir.Xcribe.UsersController,
               description: "",
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
               controller: Elixir.Xcribe.UsersController,
               description: "",
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
               controller: Elixir.Xcribe.UsersController,
               description: "",
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
               controller: Elixir.Xcribe.UsersController,
               description: "",
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
               controller: Elixir.Xcribe.PostsController,
               description: "",
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
               controller: Elixir.Xcribe.PostsController,
               description: "",
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
               controller: Elixir.Xcribe.PostsController,
               description: "",
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
               controller: Elixir.Xcribe.PostsController,
               description: "",
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
               verb: "put"
             }
    end

    test "ignore configured namespaces", %{conn: conn} do
      conn = get(conn, notes_path(conn, :index))

      assert %Request{resource: "notes"} = ConnParser.execute(conn)
    end

    test "conn is halted before match route", %{conn: conn} do
      conn =
        conn
        |> put_req_header("authorization", "token")
        |> get(authenticated_users_path(conn, :index))

      assert ConnParser.execute(conn) == %Request{
               action: "index",
               controller: Xcribe.UsersController,
               description: "",
               header_params: [{"authorization", "token"}],
               params: %{},
               path: "/authenticated/users",
               path_params: %{},
               query_params: %{},
               request_body: %{},
               resource: "authenticated_users",
               resource_group: :authenticated,
               resp_body: "{\"message\":\"not authorized\"}",
               resp_headers: [
                 {"content-type", "application/json; charset=utf-8"},
                 {"cache-control", "max-age=0, private, must-revalidate"}
               ],
               status_code: 401,
               verb: "get"
             }
    end

    test "not found route" do
      conn = %Conn{
        host: "www.example.com",
        method: "GET",
        path_info: ["invalipath"],
        private: %{
          :phoenix_router => Xcribe.WebRouter
        }
      }

      assert ConnParser.execute(conn) == %Error{
               type: :parsing,
               message: "route not found"
             }
    end

    test "invalid router" do
      conn = %Conn{private: %{:phoenix_router => __MODULE__}}

      assert ConnParser.execute(conn) == %Error{
               type: :parsing,
               message: "invalid Router or invalid Conn"
             }

      assert ConnParser.execute(%Conn{}) == %Error{
               type: :parsing,
               message: "invalid Router or invalid Conn"
             }
    end

    test "invalid conn" do
      assert ConnParser.execute(%{}) == %Error{type: :parsing, message: "a Plug.Conn is needed"}
    end
  end
end
