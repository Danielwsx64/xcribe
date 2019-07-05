defmodule Xcribe.Helpers.Document do
  alias Xcribe.{ConnParser, Recorder}

  defmacro document(conn, opts \\ []) do
    "test " <> test_name = __CALLER__.function |> elem(0) |> to_string

    quote bind_quoted: [conn: conn, test_name: test_name, opts: opts] do
      options = Keyword.merge([as: test_name], opts)

      conn
      |> ConnParser.execute(request_description(options))
      |> Recorder.save()

      conn
    end
  end

  def request_description(options), do: Keyword.fetch!(options, :as)
end
