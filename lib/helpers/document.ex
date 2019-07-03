defmodule Xcribe.Helpers.Document do
  alias Xcribe.{ConnParser, Recorder}

  defmacro document(conn) do
    "test " <> test_name = __CALLER__.function |> elem(0) |> to_string

    quote bind_quoted: [conn: conn, test_name: test_name] do
      conn
      |> ConnParser.execute(test_name)
      |> Recorder.save()

      conn
    end
  end
end
