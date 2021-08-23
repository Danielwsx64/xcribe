defmodule Xcribe.Support.RequestsGenerator do
  alias Plug.Conn
  alias Phoenix.ConnTest
  alias Xcribe.ConnParser

  require Phoenix.ConnTest

  import Xcribe.WebRouter.Helpers

  @endpoint Xcribe.Endpoint
  @api_key_auth :md5 |> :crypto.hash("security_key") |> Base.encode16()
  @base_auth Base.encode64("username:pass")
  @bearer_auth "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxIn0.rTCH8cLoGxAm_xw68z-zXVKi9ie6xJn9tnVWjd_9ftE"

  def no_pipe_users_index do
    conn = conn()

    conn
    |> ConnTest.get(no_pipe_users_path(conn, :index))
    |> ConnParser.execute("show users")
    |> Map.put(:__meta__, %{})
  end

  def users_index(opts \\ []) do
    conn = conn()

    conn
    |> put_needed_headers(opts)
    |> ConnTest.get(users_path(conn, :index))
    |> ConnParser.execute("show users")
    |> Map.put(:__meta__, %{})
  end

  def users_show(opts \\ []) do
    conn = conn()

    conn
    |> put_needed_headers(opts)
    |> ConnTest.get(users_path(conn, :show, 1))
    |> ConnParser.execute("show user info")
    |> Map.put(:__meta__, %{})
  end

  def users_create(opts \\ []) do
    conn = conn()

    conn
    |> put_needed_headers(opts)
    |> ConnTest.post(users_path(conn, :create), %{name: "teste", age: 5})
    |> ConnParser.execute("create user")
    |> Map.put(:__meta__, %{})
  end

  def users_update(opts \\ []) do
    conn = conn()

    conn
    |> put_needed_headers(opts)
    |> ConnTest.put(users_path(conn, :update, 1), %{name: "teste", age: 5})
    |> ConnParser.execute("update user")
    |> Map.put(:__meta__, %{})
  end

  def users_delete(opts \\ []) do
    conn = conn()

    conn
    |> put_needed_headers(opts)
    |> ConnTest.delete(users_path(conn, :delete, 1))
    |> ConnParser.execute("delete user")
    |> Map.put(:__meta__, %{})
  end

  def users_custom_action(opts \\ []) do
    conn = conn()

    conn
    |> put_needed_headers(opts)
    |> ConnTest.post(users_cancel_path(conn, :cancel, 1))
    |> ConnParser.execute("custom action with user")
    |> Map.put(:__meta__, %{})
  end

  def users_posts_index(opts \\ []) do
    conn = conn()

    conn
    |> put_needed_headers(opts)
    |> ConnTest.get(users_posts_path(conn, :index, 1))
    |> ConnParser.execute("show all user posts")
    |> Map.put(:__meta__, %{})
  end

  def users_posts_create(opts \\ []) do
    conn = conn()

    conn
    |> put_needed_headers(opts)
    |> ConnTest.post(users_posts_path(conn, :create, 1), %{title: "test"})
    |> ConnParser.execute("show user post")
    |> Map.put(:__meta__, %{})
  end

  def users_posts_update(opts \\ []) do
    conn = conn()

    conn
    |> put_needed_headers(opts)
    |> ConnTest.patch(users_posts_path(conn, :update, 1, 2), %{title: "test"})
    |> ConnParser.execute("update user post")
    |> Map.put(:__meta__, %{})
  end

  defp put_needed_headers(conn, opts) do
    [:content_type_json | opts]
    |> Enum.reduce(conn, &put_header_by_opt/2)
  end

  defp put_header_by_opt(:content_type_json, conn),
    do: Conn.put_req_header(conn, "content-type", "application/json")

  defp put_header_by_opt(:basic_auth, conn),
    do: Conn.put_req_header(conn, "authorization", "Basic #{@base_auth}")

  defp put_header_by_opt(:bearer_auth, conn),
    do: Conn.put_req_header(conn, "authorization", "Bearer #{@bearer_auth}")

  defp put_header_by_opt(:api_key_auth, conn),
    do: Conn.put_req_header(conn, "authorization", @api_key_auth)

  defp put_header_by_opt(_, conn), do: conn

  defp conn(), do: ConnTest.build_conn()
end
