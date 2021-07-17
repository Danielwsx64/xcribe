defmodule Xcribe.Application do
  @moduledoc false

  use Application

  alias Xcribe.{CLI.Output, Config}

  @doc false
  def start(_type, opts) do
    Config.all_endpoints()
    |> Enum.map(&Config.fetch_config(&1))
    |> Enum.each(&check_configuration/1)

    opts
    |> Keyword.get(:children, [])
    |> Enum.concat(xcribe_children())
    |> Supervisor.start_link(strategy: :one_for_one, name: Xcribe.Supervisor)
  end

  defp xcribe_children do
    [{Xcribe.Recorder, []}]
  end

  defp check_configuration(%{serve: true} = config) do
    case Config.check_configurations(config, [:serve]) do
      {:error, errors} -> Output.print_configuration_errors(errors)
      _success -> :ok
    end
  end
end
