defmodule Xcribe.Web.PlugTest do
  use ExUnit.Case, async: false

  alias Plug.Test
  alias Xcribe.Web.Plug

  setup do
    on_exit(fn ->
      Application.delete_env(:xcribe, :output)
      Application.delete_env(:xcribe, :format)
      Application.delete_env(:xcribe, :serve)
    end)

    :ok
  end

  describe "init/1" do
    test "assgin body" do
      Application.put_env(:xcribe, :output, "specificy_name_file.json")
      assert [{:body, body}] = Plug.init([])
      assert {:ok, html} = Floki.parse_document(body)

      assert Floki.find(html, "#swagger-ui") != []
      assert body =~ "specificy_name_file.json"
    end
  end

  describe "call/2" do
    test "return doc" do
      Application.put_env(:xcribe, :serve, true)
      conn = Test.conn(:get, "/")

      response = Plug.call(conn, body: "doc_body")

      assert {200, _, "doc_body"} = Test.sent_resp(response)
    end

    test "not found route" do
      Application.put_env(:xcribe, :serve, true)
      conn = Test.conn(:get, "/invalid_route")
      response = Plug.call(conn, body: "")

      assert {404, _, "not found"} = Test.sent_resp(response)
    end

    test "return not found when serving is disabled" do
      Application.put_env(:xcribe, :serve, false)
      conn = Test.conn(:get, "/")

      response = Plug.call(conn, body: "")

      assert {404, _, "not found"} = Test.sent_resp(response)
    end
  end
end
