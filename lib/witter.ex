defmodule Xcribe.Writter do
  def write(text) do
    {:ok, file} = File.open("file.md", [:write])

    IO.binwrite(file, text)

    File.close(file)
  end
end
