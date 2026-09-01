defmodule Xcribe.Plugs.Authentication do
  import Plug.Conn

  use Phoenix.Controller, formats: [:json]

  def init(_opts), do: []

  def call(conn, _opts) do
    conn
    |> put_status(:unauthorized)
    |> json(%{message: "not authorized"})
    |> halt()
  end
end
