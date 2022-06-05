defmodule Xcribe.ConnParserTest do
  use Xcribe.ConnCase, async: true

  alias Plug.Conn
  alias Xcribe.{ConnParser, Request, Request.Error}

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
               endpoint: Xcribe.Endpoint,
               header_params: [{"authorization", "token"}],
               groups_tags: ["Users"],
               params: %{},
               path: "/users",
               path_params: %{},
               query_params: %{},
               request_body: %{},
               resource: "Users",
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

      assert ConnParser.execute(conn, description: description) == %Request{
               action: "index",
               controller: Elixir.Xcribe.UsersController,
               description: description,
               endpoint: Xcribe.Endpoint,
               header_params: [{"authorization", "token"}],
               groups_tags: ["Users"],
               params: %{},
               path: "/users",
               path_params: %{},
               query_params: %{},
               request_body: %{},
               resource: "Users",
               resp_body: "[{\"id\":1,\"name\":\"user 1\"},{\"id\":2,\"name\":\"user 2\"}]",
               resp_headers: [
                 {"content-type", "application/json; charset=utf-8"},
                 {"cache-control", "max-age=0, private, must-revalidate"}
               ],
               status_code: 200,
               verb: "get"
             }
    end

    test "define the request group tags", %{conn: conn} do
      conn =
        conn
        |> put_req_header("authorization", "token")
        |> get(users_path(conn, :index))

      assert ConnParser.execute(conn, groups_tags: ["custom tag"]) == %Request{
               action: "index",
               controller: Elixir.Xcribe.UsersController,
               description: "",
               endpoint: Xcribe.Endpoint,
               header_params: [{"authorization", "token"}],
               groups_tags: ["custom tag"],
               params: %{},
               path: "/users",
               path_params: %{},
               query_params: %{},
               request_body: %{},
               resource: "Users",
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
               endpoint: Xcribe.Endpoint,
               header_params: [{"authorization", "token"}],
               groups_tags: ["Users"],
               params: %{"users_id" => "1"},
               path: "/users/{users_id}/cancel",
               path_params: %{"users_id" => "1"},
               query_params: %{},
               request_body: %{},
               resource: "Users",
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
               endpoint: Xcribe.Endpoint,
               header_params: [{"authorization", "token"}],
               groups_tags: ["Users"],
               params: %{"id" => "1"},
               path: "/users/{id}",
               path_params: %{"id" => "1"},
               query_params: %{},
               request_body: %{},
               resource: "Users",
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
               endpoint: Xcribe.Endpoint,
               header_params: [
                 {"authorization", "token"},
                 {"content-type", "multipart/mixed; boundary=plug_conn_test"}
               ],
               groups_tags: ["Users"],
               params: %{"age" => 5, "name" => "teste"},
               path: "/users",
               path_params: %{},
               query_params: %{},
               request_body: %{"age" => 5, "name" => "teste"},
               resource: "Users",
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
               endpoint: Xcribe.Endpoint,
               header_params: [
                 {"authorization", "token"},
                 {"content-type", "multipart/mixed; boundary=plug_conn_test"}
               ],
               groups_tags: ["Users"],
               params: %{"age" => 5, "id" => "1", "name" => "teste"},
               path: "/users/{id}",
               path_params: %{"id" => "1"},
               query_params: %{},
               request_body: %{"age" => 5, "name" => "teste"},
               resource: "Users",
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
               endpoint: Xcribe.Endpoint,
               header_params: [
                 {"authorization", "token"},
                 {"content-type", "multipart/mixed; boundary=plug_conn_test"}
               ],
               groups_tags: ["Users"],
               params: %{"age" => 5, "id" => "1", "name" => "teste"},
               path: "/users/{id}",
               path_params: %{"id" => "1"},
               query_params: %{},
               request_body: %{"age" => 5, "name" => "teste"},
               resource: "Users",
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
               endpoint: Xcribe.Endpoint,
               header_params: [{"authorization", "token"}],
               groups_tags: ["Users"],
               params: %{"id" => "1"},
               path: "/users/{id}",
               path_params: %{"id" => "1"},
               query_params: %{},
               request_body: %{},
               resource: "Users",
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
               endpoint: Xcribe.Endpoint,
               header_params: [{"authorization", "token"}],
               groups_tags: ["Users Posts"],
               params: %{"users_id" => "1"},
               path: "/users/{users_id}/posts",
               path_params: %{"users_id" => "1"},
               query_params: %{},
               request_body: %{},
               resource: "Users Posts",
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
               endpoint: Xcribe.Endpoint,
               header_params: [
                 {"authorization", "token"},
                 {"content-type", "multipart/mixed; boundary=plug_conn_test"}
               ],
               groups_tags: ["Users Posts"],
               params: %{"title" => "test", "users_id" => "1"},
               path: "/users/{users_id}/posts",
               path_params: %{"users_id" => "1"},
               query_params: %{},
               request_body: %{"title" => "test"},
               resource: "Users Posts",
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
               endpoint: Xcribe.Endpoint,
               header_params: [
                 {"authorization", "token"},
                 {"content-type", "multipart/mixed; boundary=plug_conn_test"}
               ],
               groups_tags: ["Users Posts"],
               params: %{"id" => "2", "title" => "test", "users_id" => "1"},
               path: "/users/{users_id}/posts/{id}",
               path_params: %{"id" => "2", "users_id" => "1"},
               query_params: %{},
               request_body: %{"title" => "test"},
               resource: "Users Posts",
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
               endpoint: Xcribe.Endpoint,
               header_params: [
                 {"authorization", "token"},
                 {"content-type", "multipart/mixed; boundary=plug_conn_test"}
               ],
               groups_tags: ["Users Posts"],
               params: %{"id" => "2", "title" => "test", "users_id" => "1"},
               path: "/users/{users_id}/posts/{id}",
               path_params: %{"id" => "2", "users_id" => "1"},
               query_params: %{},
               request_body: %{"title" => "test"},
               resource: "Users Posts",
               resp_body: "{\"title\":\"test\",\"users_id\":\"1\"}",
               resp_headers: [
                 {"content-type", "application/json; charset=utf-8"},
                 {"cache-control", "max-age=0, private, must-revalidate"}
               ],
               status_code: 200,
               verb: "put"
             }
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
               endpoint: Xcribe.Endpoint,
               header_params: [{"authorization", "token"}],
               groups_tags: ["Authenticated Users"],
               params: %{},
               path: "/authenticated/users",
               path_params: %{},
               query_params: %{},
               request_body: %{},
               resource: "Authenticated Users",
               resp_body: "{\"message\":\"not authorized\"}",
               resp_headers: [
                 {"content-type", "application/json; charset=utf-8"},
                 {"cache-control", "max-age=0, private, must-revalidate"}
               ],
               status_code: 401,
               verb: "get"
             }
    end

    test "route without pipelines", %{conn: conn} do
      conn = get(conn, no_pipe_users_path(conn, :index))

      assert ConnParser.execute(conn) == %Request{
               action: "index",
               controller: Xcribe.UsersController,
               description: "",
               endpoint: Xcribe.Endpoint,
               header_params: [],
               groups_tags: ["Nopipe Users"],
               params: %{},
               path: "/nopipe/users",
               path_params: %{},
               query_params: %{},
               request_body: %{},
               resource: "Nopipe Users",
               resp_body: "[{\"id\":1,\"name\":\"user 1\"},{\"id\":2,\"name\":\"user 2\"}]",
               resp_headers: [
                 {"content-type", "application/json; charset=utf-8"},
                 {"cache-control", "max-age=0, private, must-revalidate"}
               ],
               status_code: 200,
               verb: "get"
             }
    end

    test "route with underscore on namespace", %{conn: conn} do
      conn =
        conn
        |> put_req_header("authorization", "token")
        |> post(namespaced_users_path(conn, :index))

      assert ConnParser.execute(conn) == %Request{
               __meta__: nil,
               action: "create",
               controller: Xcribe.UsersController,
               description: "",
               endpoint: Xcribe.Endpoint,
               groups_tags: ["Namespace With Undescore Users"],
               header_params: [{"authorization", "token"}],
               params: %{},
               path: "/namespace_with_undescore/users",
               path_params: %{},
               query_params: %{},
               request_body: %{},
               resource: "Namespace With Undescore Users",
               resp_body: "{}",
               resp_headers: [
                 {"content-type", "application/json; charset=utf-8"},
                 {"cache-control", "max-age=0, private, must-revalidate"}
               ],
               status_code: 201,
               verb: "post"
             }
    end

    test "Old Phoenix router support", %{conn: conn} do
      defmodule OldRouter do
        def __match_route__(_method, _uri, _host) do
          {%{
             path_params: %{},
             pipe_through: [:api],
             plug: Xcribe.UsersController,
             opts: :index,
             route: "/users"
           }, nil, nil, nil}
        end
      end

      conn = get(conn, users_path(conn, :index))

      conn = %{conn | private: Map.put(conn.private, :phoenix_router, OldRouter)}

      assert ConnParser.execute(conn) == %Request{
               action: "index",
               controller: Elixir.Xcribe.UsersController,
               description: "",
               endpoint: Xcribe.Endpoint,
               header_params: [],
               groups_tags: ["Users"],
               params: %{},
               path: "/users",
               path_params: %{},
               query_params: %{},
               request_body: %{},
               resource: "Users",
               resp_body: "[{\"id\":1,\"name\":\"user 1\"},{\"id\":2,\"name\":\"user 2\"}]",
               resp_headers: [
                 {"content-type", "application/json; charset=utf-8"},
                 {"cache-control", "max-age=0, private, must-revalidate"}
               ],
               status_code: 200,
               verb: "get"
             }
    end

    test "define schemas" do
      conn = %Plug.Conn{
        body_params: %{},
        method: "GET",
        params: %{},
        path_info: ["users"],
        path_params: %{},
        private: %{
          Xcribe.WebRouter => {[], %{}},
          :phoenix_action => :index,
          :phoenix_controller => Xcribe.UsersController,
          :phoenix_endpoint => Xcribe.Endpoint,
          :phoenix_router => Xcribe.WebRouter
        },
        query_params: %{},
        req_headers: [],
        request_path: "/users",
        resp_body: "[]",
        resp_headers: [],
        status: 200
      }

      assert %{
               schema: "CustomSchema",
               req_schema: "CustomReqSchema"
             } = ConnParser.execute(conn, schema: "CustomSchema", req_schema: "CustomReqSchema")
    end

    test "schemas defined by module attributes" do
      conn = %Plug.Conn{
        body_params: %{},
        method: "GET",
        params: %{},
        path_info: ["users"],
        path_params: %{},
        private: %{
          Xcribe.WebRouter => {[], %{}},
          :phoenix_action => :index,
          :phoenix_controller => Xcribe.UsersController,
          :phoenix_endpoint => Xcribe.Endpoint,
          :phoenix_router => Xcribe.WebRouter
        },
        query_params: %{},
        req_headers: [],
        request_path: "/users",
        resp_body: "[]",
        resp_headers: [],
        status: 200
      }

      assert %{
               schema: "CustomSchema",
               req_schema: "CustomReqSchema"
             } =
               ConnParser.execute(conn,
                 schema: {:module, "CustomSchema"},
                 req_schema: {:module, "CustomReqSchema"}
               )
    end

    test "invalid schema error", %{conn: conn} do
      conn =
        conn
        |> put_req_header("authorization", "token")
        |> get(users_path(conn, :index))

      assert ConnParser.execute(conn, schema: 1) == %Error{
               type: :parsing,
               message: "An invalid schema name was given. Schema names MUST be an String.t()"
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
               message: "A route wasn't found for given Conn"
             }
    end

    test "invalid router" do
      conn = %Conn{private: %{:phoenix_router => __MODULE__}}

      assert ConnParser.execute(conn) == %Error{
               type: :parsing,
               message: "An invalid Plug.Conn was given or maybe an invalid Router"
             }

      assert ConnParser.execute(%Conn{}) == %Error{
               type: :parsing,
               message: "An invalid Plug.Conn was given or maybe an invalid Router"
             }
    end

    test "invalid conn" do
      assert ConnParser.execute(%{}) == %Error{
               type: :parsing,
               message: "A Plug.Conn must be given"
             }
    end
  end
end
