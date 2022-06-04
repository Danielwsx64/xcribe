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

  You can specify custom groups tags by passing the option `tags` to `document/2`

      test "test name", %{conn: conn} do
        ...

        document(conn, as: "description here", tags: ["User endpoints"])

        ...
      end

  You also can use a module attribute `@xcribe_tags` to define the groups tags 
  inside a test file.

      Module YourAppTest do
        use ExUnit.Case

        @xcribe_tags ["Authenticated API"]

        test "test name", %{conn: conn} do
          ...

          document(conn)

          ...
        end
      end
  """
  defmacro document(conn, opts \\ []) do
    register_xcribe_tag(__CALLER__)
    test_description = __CALLER__.function |> elem(0) |> to_string()

    meta =
      Macro.escape(%{
        call: %{description: test_description, file: __CALLER__.file, line: __CALLER__.line}
      })

    options = build_opts(opts, test_description, __CALLER__)

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

  defp register_xcribe_tag(%{module: module, function: {function, _arity}}) do
    module
    |> Module.delete_attribute(:ex_unit_tests)
    |> Enum.each(fn test ->
      to_put = if test.name == function, do: add_xcribe_tag(test), else: test

      Module.put_attribute(module, :ex_unit_tests, to_put)
    end)
  end

  defp build_opts(opts, "test " <> desc, %{module: module}) do
    description = Keyword.get(opts, :as, desc)

    # TODO: devolver nil quando não tiver tags definidas
    groups_tags =
      opts
      |> Keyword.get(:tags, Module.get_attribute(module, :xcribe_tags))
      |> List.wrap()

    [
      description: description,
      groups_tags: groups_tags
    ]
  end

  defp add_xcribe_tag(%{tags: tags} = test) do
    %{test | tags: Map.put(tags, :xcribe_document, true)}
  end
end
