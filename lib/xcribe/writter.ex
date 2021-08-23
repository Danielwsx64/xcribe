defmodule Xcribe.Writter do
  @moduledoc false

  alias Xcribe.CLI.Output

  @doc """
  This writes the given text to the configured output file
  """
  def write(text, %{output: output_file}) do
    output_file
    |> Path.dirname()
    |> File.mkdir_p!()

    case File.open(output_file, [:write]) do
      {:ok, file} ->
        IO.binwrite(file, text)

        Output.print_message("Xcribe documentation written in #{output_file}")

        File.close(file)

      {:error, reason} ->
        Output.print_file_errors({output_file, reason})
        :error
    end
  end
end
