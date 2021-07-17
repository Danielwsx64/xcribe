defmodule Xcribe.Formatter do
  @moduledoc """
  An implementation of ExUnit Formatter.

  This module is a `GenServer` that receives ExUnits events from your test suite.
  It handles the `suite_finished` event and then generates the documentation from
  the collected requests.

  You must add `Xcribe.Formatter` in the list of formatters in your `test_helper.exs`.

      ExUnit.start(formatters: [ExUnit.CLIFormatter, Xcribe.Formatter])

  You must keep `ExUnit.CLIFormatter` in the list as well.

  The document will be generated if the pre-configured env var has a truthy value.
  Other wise the Formatter will ignore the finished event.

  All request documented with macro `document/2` (See `Xcribe`) will be parsed
  by Xcribe. When the test suite finish `Xcribe.Formatter` will check if all
  colleted requests are valid. If some invalid request is found, an error output
  will appear and the documentation will not be generated.
  """
  use GenServer

  alias Xcribe.{CLI.Output, Config, DocException, Recorder}

  @doc false
  def init(_config) do
    active = (Config.active?() && true) || false

    {:ok, active?: active}
  end

  @doc false
  def handle_cast({:suite_finished, _run_us, _load_us}, active?: true) do
    generate_doc()

    {:noreply, :ok}
  end

  def handle_cast({:suite_finished, _time_us}, active?: true) do
    generate_doc()

    {:noreply, :ok}
  end

  def handle_cast(_event, state), do: {:noreply, state}

  defp generate_doc do
    get_records_with_endpoint()
    |> fetch_config()
    |> generate()
    |> handle_result()
  end

  defp get_records_with_endpoint do
    {errors, recorded} = Map.pop(Recorder.pop_all(), :errors)

    case Map.keys(recorded) do
      [endpoint | _ignored] ->
        {:ok, {endpoint, %{records: recorded[endpoint], errors: errors}}}

      [] ->
        if errors == [], do: {:error, "no records"}, else: {:error, errors}
    end
  end

  defp fetch_config({:ok, {endpoint, recorded}}) do
    endpoint
    |> Config.fetch_config()
    |> Config.check_configurations()
    |> case do
      {:ok, config} -> {:ok, {recorded, config}}
      {:error, _errs} = error -> error
    end
  end

  defp fetch_config(error), do: error

  defp generate({:ok, {recorded, config}}), do: Xcribe.generate_doc(recorded, config)

  defp generate(error), do: error

  defp handle_result({:error, %DocException{} = e}), do: Output.print_doc_exception(e)

  defp handle_result({:error, [error | _t] = errors}) when is_struct(error),
    do: Output.print_request_errors(errors)

  defp handle_result({:error, errors}) when is_list(errors),
    do: Output.print_configuration_errors(errors)

  defp handle_result(_any), do: :ok
end
