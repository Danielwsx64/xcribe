defmodule Xcribe.Formatter do
  @moduledoc """
  An implementation of ExUnit Formatter.

  This module is a `GenServer` that receives ExUnits events from your test suite.
  It handles the `suite_finished` event and then generates the documentation from
  the collected requests.

  To run Xcribe whille running `mix test` task you must add `Xcribe.Formatter`
  in the list of formatters in your `test_helper.exs`.

      ExUnit.start(formatters: [ExUnit.CLIFormatter, Xcribe.Formatter])

  You must keep "ExUnit.CLIFormatter" in the list as well.

  The document will be generated if the `XCRIBE_ENV` env var has a truthy value.
  Other wise the Formatter will ignore the finished event. Ex:

  ```sh
  XCRIBE_ENV=true mix test
  ```

  All request documented with macro `document/2` (See `Xcribe.Document`) will be parsed
  by Xcribe. When the test suite finish `Xcribe.Formatter` will check if all
  colleted requests are valid. If some invalid request is found, an error output
  will appear and the documentation will not be generated.
  """
  use GenServer

  alias Xcribe.Recorder

  @doc false
  def init(_config) do
    {:ok, active?: Recorder.active?()}
  end

  @doc false
  def handle_cast({:suite_finished, _run_us, _load_us}, active?: true) do
    Xcribe.document_all_records()

    {:noreply, :ok}
  end

  def handle_cast({:suite_finished, _time_us}, active?: true) do
    Xcribe.document_all_records()

    {:noreply, :ok}
  end

  def handle_cast(_event, state), do: {:noreply, state}
end
