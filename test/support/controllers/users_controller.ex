defmodule Xcribe.UsersController do
  use Phoenix.Controller, namespace: Xcribe

  def index(conn, _params) do
    conn
    |> put_status(:ok)
    |> json([%{id: 1, name: "user 1"}, %{id: 2, name: "user 2"}])
  end

  def show(conn, _params) do
    conn
    |> put_status(:ok)
    |> json(%{id: 1, name: "user 1"})
  end

  def create(conn, params) do
    conn
    |> put_status(:created)
    |> json(params)
  end

  def update(conn, params) do
    params = Map.delete(params, "id")

    conn
    |> put_status(:ok)
    |> json(params)
  end

  def delete(conn, _params) do
    conn
    |> send_resp(:no_content, "")
  end

  def cancel(conn, _params) do
    conn
    |> send_resp(:no_content, "")
  end
end
