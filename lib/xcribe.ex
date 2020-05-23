defmodule Xcribe do
  @moduledoc """
  Xcribe is a library for API documentation. It generates docs from your test specs.
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

  @doc false
  def case do
    quote do
      import Xcribe.Helpers.Document
    end
  end

  @doc false
  def information do
    quote do
      use Xcribe.Information
    end
  end

  @doc false
  defmacro __using__(mode) when is_atom(mode) do
    apply(__MODULE__, mode, [])
  end
end
