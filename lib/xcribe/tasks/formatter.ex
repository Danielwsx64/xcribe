defmodule Xcribe.Tasks.Formatter do
  @moduledoc false
  use GenServer

  alias Xcribe.CLI.Output

  def init(opts) do
    ExUnit.CLIFormatter.init(opts)
  end

  def handle_cast({:test_finished, %{state: nil} = test}, state) do
    Output.print_captured_test(test)

    {:noreply, state}
  end

  def handle_cast({:test_finished, %{state: {:failed, _reason}} = test} = event, state) do
    Output.print_captured_error(test)
    ExUnit.CLIFormatter.handle_cast(event, state)

    {:noreply, state}
  end

  def handle_cast(_event, state) do
    {:noreply, state}
  end
end
