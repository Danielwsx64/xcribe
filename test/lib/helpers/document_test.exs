defmodule Xcribe.Helpers.DocumentTest do
  use Xcribe.ConnCase, async: true

  require Xcribe.Helpers.Document

  alias Xcribe.{ConnParser, Recorder}
  alias Xcribe.Helpers.Document

  describe "document/1" do
    test "parse conn and save it", %{conn: conn} do
      Recorder.start_link()

      conn =
        conn
        |> put_req_header("authorization", "token")
        |> get(users_path(conn, :index))
        |> Document.document()

      test_name = "document/1 parse conn and save it"
      expected_record = [ConnParser.execute(conn, test_name)]

      assert Recorder.get_all() == expected_record
    end
  end
end
