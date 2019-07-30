defmodule Xcribe.Writter do
  @moduledoc """
  Writes the documentation to an file on the project.
  """

  @doc """
  This writes the given text to the configured output file
  """
  def write(text) do
    {:ok, file} = File.open(file_name(), [:write])

    IO.binwrite(file, text)

    File.close(file)
  end

  defp file_name, do: Application.get_env(:xcribe, :output_file, "api_doc.apib")
end
