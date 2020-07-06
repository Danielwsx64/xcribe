defmodule Xcribe.Web.Plug do
  @moduledoc false

  use Plug.Router

  alias Plug.Conn
  alias Xcribe.Config

  plug(Plug.Static, at: "/", from: :xcribe)
  plug(:match)
  plug(:dispatch)

  @template [Path.dirname(__ENV__.file), "template.eex"] |> Path.join() |> File.read!()

  get "/" do
    if Config.serving?() do
      uri =
        URI.to_string(%URI{
          host: conn.host,
          path: conn.request_path,
          port: conn.port,
          scheme: to_string(conn.scheme)
        })

      body = EEx.eval_string(@template, file: conn.assigns.file, uri: uri)

      send_resp(conn, 200, body)
    else
      not_found(conn)
    end
  end

  match(_, do: not_found(conn))

  def init(_opts) do
    file = String.replace_prefix(Config.output_file(), "priv/static", "")

    [file: file]
  end

  def call(conn, file: file) do
    conn
    |> Conn.assign(:file, file)
    |> super([])
  end

  defp not_found(conn), do: send_resp(conn, 404, "not found")
end
