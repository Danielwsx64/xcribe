defmodule Xcribe.Writter do
  @moduledoc false

  alias Xcribe.CLI.Output
  alias Xcribe.Config

  @doc """
  This writes the given text to the configured output file
  """
  def write(text) do
    output_file = Config.fetch(:output_file)

    output_file
    |> Path.dirname()
    |> File.mkdir_p!()

    case File.open(output_file, [:write]) do
      {:ok, file} ->
        IO.binwrite(file, text)

        IO.puts(
          "#{IO.ANSI.cyan()}> Xcribe documentation written in #{output_file}#{IO.ANSI.reset()}"
        )

        File.close(file)

      {:error, reason} ->
        Output.print_file_errors({output_file, reason})
        :error
    end
  end
end
