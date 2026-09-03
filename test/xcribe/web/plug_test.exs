defmodule Xcribe.Web.PlugTest do
  use ExUnit.Case, async: false

  alias Plug.Conn
  alias Plug.Test
  alias Xcribe.Web.Plug

  setup do
    on_exit(fn ->
      :xcribe
      |> Application.get_all_env()
      |> Keyword.keys()
      |> Enum.each(&Application.delete_env(:xcribe, &1))
    end)
  end

  describe "init/1" do
    test "return file name and serving config" do
      Application.put_env(:xcribe, Xcribe.Endpoint,
        file_name: "specificy_name_file.json",
        serve: true
      )

      assert Plug.init(endpoint: Xcribe.Endpoint) == [
               file: "specificy_name_file.json",
               serving?: true
             ]
    end

    test "serving false" do
      assert Plug.init(endpoint: Xcribe.Endpoint) == [file: "openapi.json", serving?: false]
    end

    test "trim priv namespace" do
      Application.put_env(:xcribe, Xcribe.Endpoint,
        file_name: "doc.json",
        file_path: "priv/static/"
      )

      assert Plug.init(endpoint: Xcribe.Endpoint) == [file: "doc.json", serving?: false]
    end
  end

  describe "call/2" do
    test "return doc" do
      conn = Test.conn(:get, "/")

      response = Plug.call(conn, file: "file.json", serving?: true)

      assert Conn.get_resp_header(response, "content-type") == ["text/html; charset=utf-8"]
      assert {200, _headers, body} = Test.sent_resp(response)

      assert {:ok, html} = Floki.parse_document(body)

      assert Floki.find(html, "#swagger-ui") != []

      assert html |> Floki.find("link[type='text/css']") |> Floki.attribute("href") == [
               "http://www.example.com//swagger-ui.css",
               "http://www.example.com//index.css"
             ]

      assert html |> Floki.find("link[rel='icon'][sizes='32x32']") |> Floki.attribute("href") == [
               "http://www.example.com//favicon-32x32.png"
             ]

      assert html |> Floki.find("link[rel='icon'][sizes='16x16']") |> Floki.attribute("href") == [
               "http://www.example.com//favicon-16x16.png"
             ]

      assert [bundle, preset, script] = Floki.find(html, "script")

      assert Floki.attribute(bundle, "src") == [
               "http://www.example.com//swagger-ui-bundle.js"
             ]

      assert Floki.attribute(preset, "src") == [
               "http://www.example.com//swagger-ui-standalone-preset.js"
             ]

      assert Floki.text(script, js: true) =~ "file.json"
    end

    test "not found route" do
      conn = Test.conn(:get, "/invalid_route")
      response = Plug.call(conn, file: "file", serving?: true)

      assert {404, _headers, "not found"} = Test.sent_resp(response)
    end

    test "return not found when serving is disabled" do
      conn = Test.conn(:get, "/")

      response = Plug.call(conn, file: "file", serving?: false)

      assert {404, _headers, "not found"} = Test.sent_resp(response)
    end
  end
end
