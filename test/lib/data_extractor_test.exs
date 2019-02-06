defmodule ApiBluefy.DataExtractorTest do
  use ApiBluefy.ConnCase, async: true

  alias ApiBluefy.{DataExtractor, Structs.ParsedRequest}

  describe "from_conn/1" do
    test "extract request data from conn with no body", %{conn: conn} do
      conn =
        conn
        |> put_req_header("authorization", "token")
        |> get(users_path(conn, :index))

      assert DataExtractor.from_conn(conn) == %ParsedRequest{
               paramters: [],
               action: :index,
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
               status_code: 200
             }
    end

    test "extract request data from conn with body", %{conn: conn} do
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
               body: %{"age" => 5, "name" => "teste"},
               headers: [
                 {"authorization", "token"},
                 {"content-type", "multipart/mixed; boundary=plug_conn_test"}
               ],
               paramters: ["age", "name"],
               resp_body: "{\"age\":5,\"name\":\"teste\"}",
               status_code: 201
             }
    end
  end
end
