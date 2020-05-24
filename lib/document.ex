defmodule Xcribe.Document do
  @moduledoc """
  Exposes document/2 macro to be used in test specs.
  """

  alias Xcribe.{Config, ConnParser, Recorder}

  @doc """
  Document a request by a given `Plug.Conn`.

  Each connection sent to documenting in your tests is parsed. Is expected that
  connection has been passed through the app `Endpoint` as a finished request.
  The parser will extract all needed info from `Conn` and uses app `Router`
  for additional information about the request.

  The attribute `description` may be given at `document` macro call with the
  option `:as`:

      test "test name", %{conn: conn} do
        ...

        document(conn, as: "description here")

        ...
      end

  If no description is given the current test description will be used.
  """
  defmacro document(conn, opts \\ []) do
    "test " <> test_name = __CALLER__.function |> elem(0) |> to_string

    quote bind_quoted: [conn: conn, test_name: test_name, opts: opts] do
      options = Keyword.merge([as: test_name], opts)

      if Config.active?() do
        conn
        |> ConnParser.execute(request_description(options))
        |> Recorder.save()
      end

      conn
    end
  end

  def request_description(options), do: Keyword.fetch!(options, :as)
end
