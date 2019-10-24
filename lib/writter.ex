defmodule Xcribe.Writter do
  @moduledoc """
  Writes the documentation to an file on the project.
  """

  alias Xcribe.Config

  @doc """
  This writes the given text to the configured output file
  """
  def write(text) do
    {:ok, file} = File.open(Config.output_file(), [:write])

    IO.binwrite(file, text)

    File.close(file)
  end
end
