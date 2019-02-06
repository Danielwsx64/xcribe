defmodule ApiBluefy.UsersController do
  use Phoenix.Controller, namespace: ApiBluefy
  import Plug.Conn
  alias ApiBluefy.Router.Helpers, as: Routes

  def index(conn, _params) do
    conn
    |> put_status(:ok)
    |> json([%{id: 1, name: "user 1"}, %{id: 2, name: "user 2"}])
  end

  def create(conn, params) do
    conn
    |> put_status(:created)
    |> json(params)
  end
end
