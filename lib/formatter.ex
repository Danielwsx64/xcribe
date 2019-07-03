defmodule Xcribe.Formatter do
  use GenServer

  alias Xcribe.{ApiBlueprint, Recorder, Writter}

  def init(_config) do
    {:ok, nil}
  end

  def handle_cast({:suite_finished, _run_us, _load_us}, nil) do
    Recorder.get_all()
    |> ApiBlueprint.generate_doc()
    |> Writter.write()

    {:noreply, nil}
  end

  def handle_cast(_event, nil), do: {:noreply, nil}
end
