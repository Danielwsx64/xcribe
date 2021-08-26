defmodule Xcribe.Document do
  @moduledoc """
  Exposes document/2 macro to be used in test specs.
  """

  alias Xcribe.{ConnParser, Recorder}

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
    register_xcribe_tag(__CALLER__)

    test_description = __CALLER__.function |> elem(0) |> to_string
    "test " <> description = test_description

    meta =
      Macro.escape(%{
        call: %{description: test_description, file: __CALLER__.file, line: __CALLER__.line}
      })

    options = [description: Keyword.get(opts, :as, description)]

    quote bind_quoted: [conn: conn, options: options, meta: meta] do
      if Recorder.active?() do
        conn
        |> ConnParser.execute(options)
        |> Map.put(:__meta__, meta)
        |> Recorder.add()
      end

      conn
    end
  end

  def register_xcribe_tag(%{module: module, function: {function, _arity}}) do
    module
    |> Module.delete_attribute(:ex_unit_tests)
    |> Enum.each(fn test ->
      to_put = if test.name == function, do: add_xcribe_tag(test), else: test

      Module.put_attribute(module, :ex_unit_tests, to_put)
    end)
  end

  defp add_xcribe_tag(%{tags: tags} = test) do
    %{test | tags: Map.put(tags, :xcribe_document, true)}
  end
end
