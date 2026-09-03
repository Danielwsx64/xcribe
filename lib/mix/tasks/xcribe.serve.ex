defmodule Mix.Tasks.Xcribe.Serve do
  use Mix.Task

  @requirements ["app.config"]

  alias Xcribe.{CLI.Output, Config}

  @doc false
  def run(opts) do
    with {:ok, endpoint} <- fetch_endpoint(opts),
         {:ok, config} <- fetch_config(endpoint),
         {:ok, supervisor} <- start_server(config),
         {:ok, _config} <- Config.check_configurations(config, [:serve]) do
      ref = Process.monitor(supervisor)

      if(Config.open_browser?(), do: open_browser())

      receive do
        {:DOWN, ^ref, :process, ^supervisor, reason} -> exit(reason)
      end
    else
      {:error, errors} ->
        Output.print_configuration_errors(errors)

        Output.print_message("Xcribe Task - aborted", :error)

        exit({:shutdown, 1})
    end
  end

  defp fetch_config(endpoint) do
    endpoint
    |> Config.fetch_config()
    |> Map.put(:serve, true)
    |> then(&{:ok, &1})
  end

  defp start_server(config) do
    children = [
      config.endpoint,
      {Bandit,
       plug: {Xcribe.Web.Plug, endpoint: config.endpoint, serving?: true},
       port: Config.server_port()}
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end

  defp fetch_endpoint(opts) do
    opts
    |> OptionParser.parse_head(aliases: [e: :endpoint], strict: [endpoint: :string])
    |> then(&Map.new(elem(&1, 0)))
    |> handle_endpoint()
  end

  defp handle_endpoint(%{endpoint: endpoint}) do
    "Elixir.#{endpoint}"
    |> String.to_existing_atom()
    |> tap(&Code.ensure_loaded?/1)
    |> then(&if(&1 in Config.all_endpoints(), do: {:ok, &1}, else: endpoint_error(endpoint)))
  rescue
    ArgumentError -> endpoint_error(endpoint)
  end

  defp handle_endpoint(_map) do
    {:ok, Config.all_endpoints() |> IO.inspect() |> List.first()}
  end

  defp endpoint_error(endpoint) do
    {:error,
     [{:endpoint, endpoint, "Couldn't find a configuration for endpoint #{endpoint}", ""}]}
  end

  defp open_browser do
    url = "http://localhost:#{Config.server_port()}"

    {cmd, args} =
      case :os.type() do
        {:win32, _} -> {"cmd", ["/c", "start", url]}
        {:unix, :darwin} -> {"open", [url]}
        {:unix, _} -> {"xdg-open", [url]}
      end

    System.cmd(cmd, args)
  end
end
