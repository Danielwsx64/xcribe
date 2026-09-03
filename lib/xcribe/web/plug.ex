defmodule Xcribe.Web.Plug do
  @moduledoc """
  Server generated API documentation.

  Add a doc scope to your router, and forward all requests to `Xcribe.Web.Plug`

  ```
        scope "doc/openapi" do
          forward "/", Xcribe.Web.Plug, endpoint: YourApp.Endpoint
        end

  ```
  """

  use Plug.Router

  require EEx

  alias Plug.Conn
  alias Xcribe.Config

  plug(Plug.Static, at: "/", from: :xcribe)
  plug(:match)
  plug(:dispatch)

  @swagger_ui_template Path.expand("../../../priv/templates/swagger_ui.eex", __DIR__)

  EEx.function_from_file(:defp, :swagger_ui, @swagger_ui_template, [:file, :uri])

  get "/" do
    if conn.assigns.serving? do
      uri =
        URI.to_string(%URI{
          host: conn.host,
          path: conn.request_path,
          port: conn.port,
          scheme: to_string(conn.scheme)
        })

      conn
      |> Conn.put_resp_header("content-type", "text/html; charset=utf-8")
      |> send_resp(200, swagger_ui(conn.assigns.file, uri))
    else
      not_found(conn)
    end
  end

  match(_, do: not_found(conn))

  @doc false
  def init(opts) do
    endpoint = Keyword.fetch!(opts, :endpoint)

    config = Config.fetch_config(endpoint)

    [
      file: Config.get_serving_path(config),
      serving?: Keyword.get(opts, :serving?, config.serve),
      endpoint: endpoint
    ]
  end

  @doc false
  def call(conn, file: file, serving?: serving, endpoint: endpoint) do
    if file == String.replace_leading(conn.request_path, "/", "") do
      endpoint.call(conn, [])
    else
      conn
      |> Conn.assign(:file, file)
      |> Conn.assign(:serving?, serving)
      |> super([])
    end
  end

  defp not_found(conn), do: send_resp(conn, 404, "not found")
end
