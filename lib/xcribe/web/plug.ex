defmodule Xcribe.Web.Plug do
  @moduledoc """
  Server generated API documentation.

  Add a doc scope to your router, and forward all requests to `Xcribe.Web.Plug`

  ```
        scope "doc/swagger" do
          forward "/", Xcribe.Web.Plug
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
    if Config.serving?() do
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
  def init(_opts) do
    file = String.replace_prefix(Config.output_file(), "priv/static", "")

    [file: file]
  end

  @doc false
  def call(conn, file: file) do
    conn
    |> Conn.assign(:file, file)
    |> super([])
  end

  defp not_found(conn), do: send_resp(conn, 404, "not found")
end
