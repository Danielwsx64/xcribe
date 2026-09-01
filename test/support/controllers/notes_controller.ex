defmodule Xcribe.NotesController do
  use Phoenix.Controller, namespace: Xcribe

  def index(conn, _params) do
    conn
    |> put_status(:ok)
    |> json([])
  end
end
