defmodule Xcribe.Formatter do
  use GenServer

  require Logger

  alias Xcribe.{ApiBlueprint, Config, Recorder, Swagger, Writter}

  def init(_config) do
    {:ok, nil}
  end

  def handle_cast({:suite_finished, _run_us, _load_us}, nil) do
    if Config.active?() do
      Recorder.get_all()
      |> generate_docs(Config.doc_format())
      |> write()
    end

    {:noreply, nil}
  end

  def handle_cast(_event, nil), do: {:noreply, nil}

  defp generate_docs(requests, :api_blueprint), do: ApiBlueprint.generate_doc(requests)
  defp generate_docs(requests, :swagger), do: Swagger.generate_doc(requests)
  defp generate_docs(_, _), do: {:error, "invalid format"}

  defp write({:error, reason}), do: Logger.warn("Could not write file for reason: #{reason}")
  defp write(text), do: Writter.write(text)
end
