defmodule Xcribe.Application do
  @moduledoc false

  use Application

  alias Xcribe.CLI.Output
  alias Xcribe.Config

  @doc false
  def start(_type, opts) do
    case Config.check_configurations([:serving?]) do
      {:error, errors} -> Output.print_configuration_errors(errors)
      :ok -> :ok
    end

    opts
    |> Keyword.get(:children, [])
    |> Enum.concat(xcribe_children())
    |> Supervisor.start_link(strategy: :one_for_one, name: Xcribe.Supervisor)
  end

  defp xcribe_children do
    [
      {Xcribe.Config, []},
      {Xcribe.Recorder, []}
    ]
  end
end
