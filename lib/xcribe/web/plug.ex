defmodule Xcribe.Web.Plug do
  @moduledoc """
  Server generated API documentation.

  Add a doc scope to your router, and forward all requests to `Xcribe.Web.Plug`

  ```
        scope "doc/swagger" do
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

  EEx.function_from_file(
    :defp,
    :swagger_ui,
    Path.join([File.cwd!(), "priv", "templates", "swagger_ui.eex"]),
    [:file, :uri]
  )

  get "/" do
    if conn.assigns.serving? do
      uri =
        URI.to_string(%URI{
          host: conn.host,
          path: conn.request_path,
          port: conn.port,
          scheme: to_string(conn.scheme)
        })

      send_resp(conn, 200, swagger_ui(conn.assigns.file, uri))
    else
      not_found(conn)
    end
  end

  match(_, do: not_found(conn))

  @doc false
  def init(opts) do
    endpoint = Keyword.fetch!(opts, :endpoint)

    config = Config.fetch_config(endpoint)

    file = String.replace_prefix(config.output, "priv/static", "")

    [file: file, serving?: config.serve]
  end

  @doc false
  def call(conn, file: file, serving?: serving) do
    conn
    |> Conn.assign(:file, file)
    |> Conn.assign(:serving?, serving)
    |> super([])
  end

  defp not_found(conn), do: send_resp(conn, 404, "not found")
end
