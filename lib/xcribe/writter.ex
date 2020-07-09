defmodule Xcribe.Writter do
  @moduledoc false

  alias Xcribe.Config

  @doc """
  This writes the given text to the configured output file
  """
  def write(text) do
    output_file = Config.output_file()

    output_file
    |> Path.dirname()
    |> File.mkdir_p!()

    {:ok, file} = File.open(output_file, [:write])

    IO.binwrite(file, text)
    IO.puts("#{IO.ANSI.cyan()}> Xcribe documentation written in #{output_file}#{IO.ANSI.reset()}")

    File.close(file)
  end
end
