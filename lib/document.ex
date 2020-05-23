defmodule Xcribe.Document do
  @moduledoc """
  Exposes document/2 macro to be used in test specs.
  """

  alias Xcribe.{Config, ConnParser, Recorder, Request, Request.Error}

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
    test_description = __CALLER__.function |> elem(0) |> to_string
    "test " <> suggest_from_test = test_description

    meta =
      Macro.escape(%{
        call: %{description: test_description, file: __CALLER__.file, line: __CALLER__.line}
      })

    quote bind_quoted: [conn: conn, opts: opts, suggestion: suggest_from_test, meta: meta] do
      options = Keyword.merge([as: suggestion], opts)

      if Config.active?() do
        conn
        |> ConnParser.execute(request_description(options))
        |> append_meta(meta)
        |> Recorder.save()
      end

      conn
    end
  end

  def append_meta(%Request{} = request, meta), do: Map.put(request, :__meta__, meta)

  def append_meta({:error, message}, meta),
    do: Map.put(%Error{type: :parsing, message: message}, :__meta__, meta)

  @doc false
  def request_description(options), do: Keyword.fetch!(options, :as)
end
