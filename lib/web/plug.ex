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
    if Config.serving?(), do: send_resp(conn, 200, conn.assigns.body), else: not_found(conn)
  end

  match(_, do: not_found(conn))

  def init(_opts) do
    doc_file = String.replace_prefix(Config.output_file(), "priv/static", "")
    body = EEx.eval_string(@template, doc_file: doc_file)

    [body: body]
  end

  def call(conn, body: body) do
    conn
    |> Conn.assign(:body, body)
    |> super([])
  end

  defp not_found(conn), do: send_resp(conn, 404, "not found")
end
