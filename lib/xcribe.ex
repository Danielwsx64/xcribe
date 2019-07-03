defmodule Xcribe do
  use Application

  def start(_type, _opts) do
    opts = [strategy: :one_for_one, name: Xcribe.Supervisor]
    Supervisor.start_link(children(), opts)
  end

  def start(_options \\ []) do
    {:ok, _} = Application.start(:xcribe)

    :ok
  end

  defp children do
    import Supervisor.Spec

    [
      worker(Xcribe.Recorder, [])
    ]
  end
end
