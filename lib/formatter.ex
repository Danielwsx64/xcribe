defmodule Xcribe.Formatter do
  @moduledoc """
  An implementation of ExUnit Formatter.

  This module is a `GenServer` that receives ExUnits events from your test suite.
  It handle the `suite_finished` event and then generates the documentation from
  the collected requests.

  You must add `Xcribe.Formatter` in the list of formatters in your `test_helper.exs`.

      ExUnit.start(formatters: [ExUnit.CLIFormatter, Xcribe.Formatter])

  You must keep `ExUnit.CLIFormatter` in the list as well.

  The  document will be generated if the pre-configured env var has a truthy value.
  Other wise the Formatter will ignore the finished event.
  """
  use GenServer

  require Logger

  alias Xcribe.{ApiBlueprint, Config, Recorder, Swagger, Writter}

  @doc false
  def init(_config) do
    {:ok, nil}
  end

  @doc false
  def handle_cast({:suite_finished, _run_us, _load_us}, nil) do
    if Config.active?() do
      Recorder.get_all()
      |> generate_docs(Config.doc_format())
      |> write()
    end

    {:noreply, nil}
  end

  @doc false
  def handle_cast(_event, nil), do: {:noreply, nil}

  defp generate_docs(requests, :api_blueprint), do: ApiBlueprint.generate_doc(requests)
  defp generate_docs(requests, :swagger), do: Swagger.generate_doc(requests)
  defp generate_docs(_, _), do: {:error, "invalid format"}

  defp write({:error, reason}), do: Logger.warn("Could not write file for reason: #{reason}")
  defp write(text), do: Writter.write(text)
end
