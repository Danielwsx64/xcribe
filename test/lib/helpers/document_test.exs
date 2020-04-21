defmodule Xcribe.Helpers.DocumentTest do
  use Xcribe.ConnCase, async: false

  alias Xcribe.{ConnParser, Recorder}

  import Xcribe.Helpers.Document

  setup do
    Application.put_all_env(
      xcribe: [env_var: "PWD", information_source: Xcribe.Support.Information]
    )

    :ok
  end

  describe "document/1" do
    test "parse conn and save it", %{conn: conn} do
      Recorder.start_link()

      conn =
        conn
        |> put_req_header("authorization", "token")
        |> get(users_path(conn, :index))
        |> document()

      test_name = "document/1 parse conn and save it"
      expected_record = [ConnParser.execute(conn, test_name)]

      assert Recorder.get_all() == expected_record
    end

    test "parse conn and save it whith custom description", %{conn: conn} do
      Recorder.start_link()

      request_description = "some description"

      conn =
        conn
        |> put_req_header("authorization", "token")
        |> get(users_path(conn, :index))
        |> document(as: request_description)

      expected_record = [ConnParser.execute(conn, request_description)]

      assert Recorder.get_all() == expected_record
    end

    test "dont document when env var is not defined", %{conn: conn} do
      Application.delete_env(:xcribe, :env_var)

      Recorder.start_link()

      conn
      |> put_req_header("authorization", "token")
      |> get(users_path(conn, :index))
      |> document()

      assert Recorder.get_all() == []
    end
  end
end
