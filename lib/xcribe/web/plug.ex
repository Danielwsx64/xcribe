defmodule Xcribe.Web.Plug do
  @moduledoc """
  Server generated API documentation.

  Add a doc scope to your router, and forward all requests to `Xcribe.Web.Plug`

  ```
        scope "/doc/openapi" do
          forward "/", Xcribe.Web.Plug, endpoint: YourApp.Endpoint
        end

  ```

  `mix xcribe.serve` serves the same documentation without touching your router,
  see `Mix.Tasks.Xcribe.Serve`.
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
      endpoint: endpoint,
      file: Config.serving_path(config),
      proxy?: Keyword.get(opts, :proxy?, false),
      serving?: Keyword.get(opts, :serving?, config.serve)
    ]
  end

  @doc false
  def call(conn, opts) do
    if proxy_document?(conn, opts) do
      endpoint = Keyword.fetch!(opts, :endpoint)

      endpoint.call(conn, [])
    else
      conn
      |> Conn.assign(:file, Keyword.fetch!(opts, :file))
      |> Conn.assign(:serving?, Keyword.fetch!(opts, :serving?))
      |> super([])
    end
  end

  defp proxy_document?(%{request_path: request_path}, opts) do
    Keyword.fetch!(opts, :proxy?) and
      Keyword.fetch!(opts, :file) == String.replace_leading(request_path, "/", "")
  end

  defp not_found(conn), do: send_resp(conn, 404, "not found")
end
