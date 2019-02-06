defmodule ApiBluefy.DataExtractorTest do
  use ApiBluefy.ConnCase, async: true

  alias ApiBluefy.{DataExtractor, Structs.ParsedConn}

  describe "from_conn/1" do
    test "extract request data from conn with no body", %{conn: conn} do
      conn =
        conn
        |> put_req_header("authorization", "token")
        |> get(users_path(conn, :index))

      assert DataExtractor.from_conn(conn) == %ParsedConn{
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
               ]
             }
    end
  end
end
