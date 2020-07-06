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
    test "return file name" do
      Application.put_env(:xcribe, :output, "specificy_name_file.json")
      assert [{:file, "specificy_name_file.json"}] = Plug.init([])
    end
  end

  describe "call/2" do
    test "return doc" do
      Application.put_env(:xcribe, :serve, true)
      conn = Test.conn(:get, "/")

      response = Plug.call(conn, file: "file.json")

      assert {200, _headers, body} = Test.sent_resp(response)

      assert {:ok, html} = Floki.parse_document(body)

      assert Floki.find(html, "#swagger-ui") != []

      assert html |> Floki.find("link[type='text/css']") |> Floki.attribute("href") == [
               "http://www.example.com//swagger-ui.css"
             ]

      assert html |> Floki.find("link[rel='icon'][sizes='32x32']") |> Floki.attribute("href") == [
               "http://www.example.com//favicon-32x32.png"
             ]

      assert html |> Floki.find("link[rel='icon'][sizes='16x16']") |> Floki.attribute("href") == [
               "http://www.example.com//favicon-16x16.png"
             ]

      assert [
               {"script", [{"src", "http://www.example.com//swagger-ui-bundle.js"}], [" "]},
               {"script", [{"src", "http://www.example.com//swagger-ui-standalone-preset.js"}],
                [" "]},
               script
             ] = Floki.find(html, "script")

      assert Floki.text(script, js: true) =~ "file.json"
    end

    test "not found route" do
      Application.put_env(:xcribe, :serve, true)
      conn = Test.conn(:get, "/invalid_route")
      response = Plug.call(conn, file: "")

      assert {404, _headers, "not found"} = Test.sent_resp(response)
    end

    test "return not found when serving is disabled" do
      Application.put_env(:xcribe, :serve, false)
      conn = Test.conn(:get, "/")

      response = Plug.call(conn, file: "")

      assert {404, _headers, "not found"} = Test.sent_resp(response)
    end
  end
end
