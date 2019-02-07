defmodule ApiBluefy.DataExtractorTest do
  use ApiBluefy.ConnCase, async: true

  alias ApiBluefy.{DataExtractor, Structs.ParsedRequest}

  describe "from_conn/1" do
    test "extract request data from an index request", %{conn: conn} do
      conn =
        conn
        |> put_req_header("authorization", "token")
        |> get(users_path(conn, :index))

      assert DataExtractor.from_conn(conn) == %ParsedRequest{
               paramters: [],
               action: :index,
               action_verb: :get,
               body: %{},
               headers: [{"authorization", "token"}],
               name: "Request",
               resource: "users",
               resource_group: :api,
               resp_body: "[{\"id\":1,\"name\":\"user 1\"},{\"id\":2,\"name\":\"user 2\"}]",
               resp_headers: [
                 {"content-type", "application/json; charset=utf-8"},
                 {"cache-control", "max-age=0, private, must-revalidate"}
               ],
               status_code: 200,
               path: "/users"
             }
    end

    test "extract request data from a show request", %{conn: conn} do
      conn =
        conn
        |> put_req_header("authorization", "token")
        |> get(users_path(conn, :show, 1))

      assert DataExtractor.from_conn(conn) == %ParsedRequest{
               paramters: ["id"],
               action: :show,
               action_verb: :get,
               body: %{},
               headers: [{"authorization", "token"}],
               name: "Request",
               resource: "users",
               resource_group: :api,
               resp_body: "{\"id\":1,\"name\":\"user 1\"}",
               resp_headers: [
                 {"content-type", "application/json; charset=utf-8"},
                 {"cache-control", "max-age=0, private, must-revalidate"}
               ],
               status_code: 200,
               path: "/users/{id}"
             }
    end

    test "extract request data from a create request", %{conn: conn} do
      conn =
        conn
        |> put_req_header("authorization", "token")
        |> post(users_path(conn, :create), %{name: "teste", age: 5})

      assert DataExtractor.from_conn(conn) == %ParsedRequest{
               name: "Request",
               resource: "users",
               resource_group: :api,
               resp_headers: [
                 {"content-type", "application/json; charset=utf-8"},
                 {"cache-control", "max-age=0, private, must-revalidate"}
               ],
               action: :create,
               action_verb: :post,
               body: %{"age" => 5, "name" => "teste"},
               headers: [
                 {"authorization", "token"},
                 {"content-type", "multipart/mixed; boundary=plug_conn_test"}
               ],
               paramters: ["age", "name"],
               resp_body: "{\"age\":5,\"name\":\"teste\"}",
               status_code: 201,
               path: "/users"
             }
    end

    test "extract request data from an update request with put", %{conn: conn} do
      conn =
        conn
        |> put_req_header("authorization", "token")
        |> put(users_path(conn, :update, 1), %{name: "teste", age: 5})

      assert DataExtractor.from_conn(conn) == %ParsedRequest{
               headers: [
                 {"authorization", "token"},
                 {"content-type", "multipart/mixed; boundary=plug_conn_test"}
               ],
               name: "Request",
               resource_group: :api,
               resp_body: "{\"age\":5,\"name\":\"teste\"}",
               resp_headers: [
                 {"content-type", "application/json; charset=utf-8"},
                 {"cache-control", "max-age=0, private, must-revalidate"}
               ],
               action: :update,
               action_verb: :put,
               body: %{"age" => 5, "name" => "teste"},
               paramters: ["age", "id", "name"],
               path: "/users/{id}",
               resource: "users",
               status_code: 200
             }
    end

    test "extract request data from an update request with patch", %{conn: conn} do
      conn =
        conn
        |> put_req_header("authorization", "token")
        |> patch(users_path(conn, :update, 1), %{name: "teste", age: 5})

      assert DataExtractor.from_conn(conn) == %ParsedRequest{
               headers: [
                 {"authorization", "token"},
                 {"content-type", "multipart/mixed; boundary=plug_conn_test"}
               ],
               name: "Request",
               resource_group: :api,
               resp_body: "{\"age\":5,\"name\":\"teste\"}",
               resp_headers: [
                 {"content-type", "application/json; charset=utf-8"},
                 {"cache-control", "max-age=0, private, must-revalidate"}
               ],
               action: :update,
               action_verb: :patch,
               body: %{"age" => 5, "name" => "teste"},
               paramters: ["age", "id", "name"],
               path: "/users/{id}",
               resource: "users",
               status_code: 200
             }
    end

    test "extract request data from a delete request", %{conn: conn} do
      conn =
        conn
        |> put_req_header("authorization", "token")
        |> delete(users_path(conn, :delete, 1))

      assert DataExtractor.from_conn(conn) == %ParsedRequest{
               headers: [
                 {"authorization", "token"}
               ],
               name: "Request",
               resource_group: :api,
               resp_body: "",
               resp_headers: [
                 {"cache-control", "max-age=0, private, must-revalidate"}
               ],
               action: :delete,
               action_verb: :delete,
               body: %{},
               paramters: ["id"],
               path: "/users/{id}",
               resource: "users",
               status_code: 204
             }
    end

    test "extract request data from a nested index request", %{conn: conn} do
      conn =
        conn
        |> put_req_header("authorization", "token")
        |> get(users_posts_path(conn, :index, 1))

      assert DataExtractor.from_conn(conn) == %ParsedRequest{
               paramters: ["users_id"],
               action: :index,
               action_verb: :get,
               body: %{},
               headers: [{"authorization", "token"}],
               name: "Request",
               resource: "users_posts",
               resource_group: :api,
               resp_body: "[{\"id\":1,\"title\":\"user 1\"},{\"id\":2,\"title\":\"user 2\"}]",
               resp_headers: [
                 {"content-type", "application/json; charset=utf-8"},
                 {"cache-control", "max-age=0, private, must-revalidate"}
               ],
               status_code: 200,
               path: "/users/{users_id}/posts"
             }
    end

    test "extract request data from a nested create request", %{conn: conn} do
      conn =
        conn
        |> put_req_header("authorization", "token")
        |> post(users_posts_path(conn, :create, 1), %{title: "test"})

      assert DataExtractor.from_conn(conn) == %ParsedRequest{
               paramters: ["title", "users_id"],
               action: :create,
               action_verb: :post,
               body: %{"title" => "test"},
               headers: [
                 {"authorization", "token"},
                 {"content-type", "multipart/mixed; boundary=plug_conn_test"}
               ],
               name: "Request",
               resource: "users_posts",
               resource_group: :api,
               resp_body: "{\"title\":\"test\",\"users_id\":\"1\"}",
               resp_headers: [
                 {"content-type", "application/json; charset=utf-8"},
                 {"cache-control", "max-age=0, private, must-revalidate"}
               ],
               status_code: 201,
               path: "/users/{users_id}/posts"
             }
    end

    test "extract request data from a nested update request", %{conn: conn} do
      conn =
        conn
        |> put_req_header("authorization", "token")
        |> patch(users_posts_path(conn, :update, 1, 2), %{title: "test"})

      assert DataExtractor.from_conn(conn) == %ParsedRequest{
               paramters: ["id", "title", "users_id"],
               action: :update,
               action_verb: :patch,
               body: %{"title" => "test"},
               headers: [
                 {"authorization", "token"},
                 {"content-type", "multipart/mixed; boundary=plug_conn_test"}
               ],
               name: "Request",
               resource: "users_posts",
               resource_group: :api,
               resp_body: "{\"title\":\"test\",\"users_id\":\"1\"}",
               resp_headers: [
                 {"content-type", "application/json; charset=utf-8"},
                 {"cache-control", "max-age=0, private, must-revalidate"}
               ],
               status_code: 200,
               path: "/users/{users_id}/posts/{id}"
             }
    end
  end
end
