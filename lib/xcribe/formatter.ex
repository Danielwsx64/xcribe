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

  alias Xcribe.Config

  @doc false
  def init(_config), do: {:ok, active?: Config.fetch(:active?)}

  @doc false
  def handle_cast({:suite_finished, _run_us, _load_us}, active?: true) do
    Xcribe.suite_finished()

    {:noreply, :ok}
  end

  def handle_cast({:suite_finished, _time_us}, active?: true) do
    Xcribe.suite_finished()

    {:noreply, :ok}
  end

  def handle_cast(_event, state), do: {:noreply, state}
end
