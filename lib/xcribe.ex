defmodule Xcribe do
  @moduledoc """
  This is the documentation for the XCribe Project

  XCribe was built to generate API documentation for your app tests.
  """
  use Application

  @doc false
  def start(_type, _opts) do
    opts = [strategy: :one_for_one, name: Xcribe.Supervisor]
    Supervisor.start_link(children(), opts)
  end

  @doc false
  def start(_options \\ []) do
    {:ok, _} = Application.start(:xcribe)

    :ok
  end

  defp children do
    import Supervisor.Spec

    [worker(Xcribe.Recorder, [])]
  end
end
