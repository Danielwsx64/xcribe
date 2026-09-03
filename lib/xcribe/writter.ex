defmodule Xcribe.Writter do
  @moduledoc false

  alias Xcribe.CLI.Output
  alias Xcribe.Config

  @doc """
  This writes the given text to the configured output file.

  `artifact` names what was written, for the success message only.
  """
  def write(text, config, artifact \\ "documentation")

  def write(text, config, artifact) do
    output_file = Config.get_output_path(config)

    output_file
    |> Path.dirname()
    |> File.mkdir_p!()

    case File.open(output_file, [:write]) do
      {:ok, file} ->
        IO.binwrite(file, text)

        Output.print_message("Xcribe #{artifact} written in #{output_file}")

        File.close(file)

      {:error, reason} ->
        Output.print_file_errors({output_file, reason})
        :error
    end
  end
end
