defmodule Mix.Tasks.Xcribe.Doc do
  @moduledoc """
  Run tests with `Xcribe.Document.document/2` macro and generate documentation.

  Note: to use this task you must configure `preferred_cli_env: ["xcribe.doc": :test]`
  on your `mix.ex` file.
  """
  use Mix.Task

  alias Xcribe.{CLI.Output, Recorder}

  @requirements ["app.start"]

  @mix_test_opts ~w[--only xcribe_document --formatter Xcribe.Tasks.Formatter --max-failures 1]

  @shortdoc "Generate Xcribe documentation by running tests"

  @doc false
  def run(_opts) do
    Recorder.set_active(true)

    Output.print_message("Xcribe Task - starting capture requests")

    Mix.Task.run("test", @mix_test_opts)

    IO.puts("\n")
    Output.print_message("Xcribe Task - starting doc generation")

    case Xcribe.document_all_records() do
      :ok ->
        Output.print_message("Xcribe Task - finished")
        :ok

      :error ->
        Output.print_message("Xcribe Task - aborted", :error)
        exit({:shutdown, 1})
    end
  end
end
