defmodule Xcribe.DocumentTest do
  use Xcribe.ConnCase, async: false

  alias Xcribe.{ConnParser, Recorder}

  import Xcribe.Document

  setup do
    Application.put_env(:xcribe, :information_source, Xcribe.Support.Information)
    Application.put_env(:xcribe, :env_var, "PWD")

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
      file_name = File.cwd!() <> "/test/lib/document_test.exs"

      parsed_request_with_meta =
        conn
        |> ConnParser.execute(test_name)
        |> Map.put(:__meta__, %{
          call: %{
            description: "test #{test_name}",
            file: file_name,
            line: 23
          }
        })

      assert Recorder.get_all() == [parsed_request_with_meta]
    end

    test "parse conn and save it whith custom description", %{conn: conn} do
      Recorder.start_link()

      request_description = "some description"

      conn =
        conn
        |> put_req_header("authorization", "token")
        |> get(users_path(conn, :index))
        |> document(as: request_description)

      test_name = "test document/1 parse conn and save it whith custom description"
      file_name = File.cwd!() <> "/test/lib/document_test.exs"

      parsed_request_with_meta =
        conn
        |> ConnParser.execute(request_description)
        |> Map.put(:__meta__, %{
          call: %{
            description: test_name,
            file: file_name,
            line: 51
          }
        })

      assert Recorder.get_all() == [parsed_request_with_meta]
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
