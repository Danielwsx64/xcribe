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

  All request documented with macro `document/2` (See `Xcribe`) will be parsed
  by Xcribe. When the test suite finish `Xcribe.Formatter` will check if all
  colleted requests are valid. If some invalid request is found an error output
  will apears and documentation will not be generated.
  """
  use GenServer

  require Logger

  alias Xcribe.{
    ApiBlueprint,
    CLI.Output,
    Config,
    Recorder,
    Request,
    Request.Error,
    Swagger,
    Writter
  }

  @doc false
  def init(_config), do: {:ok, nil}

  @doc false
  def handle_cast({:suite_finished, _run_us, _load_us}, nil) do
    if Config.active?() do
      check_configurations()
      |> get_recorded_requests()
      |> validate_records()
      |> order_by_path()
      |> generate_docs()
      |> write()
    end

    {:noreply, nil}
  end

  @doc false
  def handle_cast(_event, nil), do: {:noreply, nil}

  defp check_configurations do
    case Config.check_configurations() do
      {:error, errs} -> Output.print_configuration_errors(errs) && :error
      :ok -> :ok
    end
  end

  defp get_recorded_requests(:ok), do: Recorder.get_all()
  defp get_recorded_requests(:error), do: :error

  defp validate_records(:error), do: :error

  defp validate_records(records) when is_list(records) do
    records
    |> check_errors()
    |> handle_errors()
  end

  defp check_errors(records), do: Enum.reduce(records, {:ok, []}, &reduce_records/2)

  defp reduce_records(%Request{} = request, {:ok, requests}), do: {:ok, [request | requests]}
  defp reduce_records(%Request{}, {:error, _errs} = err), do: err

  defp reduce_records(%Error{} = err, {:ok, _requests}), do: {:error, [err]}
  defp reduce_records(%Error{} = err, {:error, errs}), do: {:error, [err | errs]}

  defp handle_errors({:error, errs}), do: Output.print_request_errors(errs) && :error
  defp handle_errors({:ok, requests}), do: requests

  defp order_by_path(:error), do: :error
  defp order_by_path(requests), do: Enum.sort(requests, &(&1.path >= &2.path))

  defp generate_docs(:error), do: :error

  defp generate_docs(requests) when is_list(requests) do
    case Config.doc_format!() do
      :api_blueprint -> ApiBlueprint.generate_doc(requests)
      :swagger -> Swagger.generate_doc(requests)
    end
  end

  defp write(:error), do: :error
  defp write(text) when is_binary(text), do: Writter.write(text)
end
