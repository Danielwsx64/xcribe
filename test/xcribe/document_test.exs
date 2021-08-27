defmodule Xcribe.DocumentTest do
  use Xcribe.ConnCase, async: false

  alias Xcribe.{Recorder, Request.Error}

  import Xcribe.Document

  setup do
    Recorder.set_active(true)
    Recorder.pop_all()

    on_exit(fn ->
      Recorder.set_active(false)
    end)
  end

  describe "document/1" do
    test "parse conn and save it with meta information", %{conn: conn} do
      conn
      |> put_req_header("authorization", "token")
      |> get(users_path(conn, :index))
      |> document()

      test_name = "document/1 parse conn and save it with meta information"
      file_name = File.cwd!() <> "/test/xcribe/document_test.exs"

      meta = %{
        call: %{
          description: "test #{test_name}",
          file: file_name,
          line: 22
        }
      }

      assert %{
               :errors => [],
               Xcribe.Endpoint => [
                 %{
                   description: ^test_name,
                   __meta__: ^meta
                 }
               ]
             } = Recorder.pop_all()
    end

    test "parse conn and save it whith custom description", %{conn: conn} do
      request_description = "some description"

      conn
      |> put_req_header("authorization", "token")
      |> get(users_path(conn, :index))
      |> document(as: request_description)

      assert %{:errors => [], Xcribe.Endpoint => [%{description: ^request_description}]} =
               Recorder.pop_all()
    end

    test "parse conn and save it whith custom groups tags", %{conn: conn} do
      conn
      |> put_req_header("authorization", "token")
      |> get(users_path(conn, :index))
      |> document(tags: ["Users", "Default"])

      assert %{:errors => [], Xcribe.Endpoint => [%{groups_tags: ["Users", "Default"]}]} =
               Recorder.pop_all()
    end

    test "wrap groups into list", %{conn: conn} do
      conn
      |> put_req_header("authorization", "token")
      |> get(users_path(conn, :index))
      |> document(tags: "Users")

      assert %{:errors => [], Xcribe.Endpoint => [%{groups_tags: ["Users"]}]} = Recorder.pop_all()
    end

    @xcribe_tags ["Custom Tag"]
    test "use module attribute to set groups tags", %{conn: conn} do
      conn
      |> put_req_header("authorization", "token")
      |> get(users_path(conn, :index))
      |> document()

      assert %{:errors => [], Xcribe.Endpoint => [%{groups_tags: ["Custom Tag"]}]} =
               Recorder.pop_all()
    end

    @xcribe_tags "Other Custom Tag"
    test "wrap module attribute into list", %{conn: conn} do
      conn
      |> put_req_header("authorization", "token")
      |> get(users_path(conn, :index))
      |> document()

      assert %{:errors => [], Xcribe.Endpoint => [%{groups_tags: ["Other Custom Tag"]}]} =
               Recorder.pop_all()
    end

    @xcribe_tags ["Custom Tag"]
    test "override module attribute with custom opts", %{conn: conn} do
      conn
      |> put_req_header("authorization", "token")
      |> get(users_path(conn, :index))
      |> document(tags: "Over Tag")

      assert %{:errors => [], Xcribe.Endpoint => [%{groups_tags: ["Over Tag"]}]} =
               Recorder.pop_all()
    end

    test "handle parse errors" do
      document(%{})

      test_name = "test document/1 handle parse errors"
      file_name = File.cwd!() <> "/test/xcribe/document_test.exs"

      parsed_request_with_meta = %Error{
        message: "A Plug.Conn must be given",
        type: :parsing,
        __meta__: %{
          call: %{
            description: test_name,
            file: file_name,
            line: __ENV__.line - 12
          }
        }
      }

      assert Recorder.pop_all() == %{errors: [parsed_request_with_meta]}
    end

    test "dont document when recorder is not active", %{conn: conn} do
      Recorder.set_active(false)

      conn
      |> put_req_header("authorization", "token")
      |> get(users_path(conn, :index))
      |> document()

      assert Recorder.pop_all() == %{errors: []}
    end
  end
end
