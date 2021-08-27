defmodule Mix.Tasks.Xcribe.Doc do
  @moduledoc """
  Run tests with `Xcribe.Document.document/2` macro and generate documentation.

  You can override the application config by passing the arguments `--format` and `--output`

  ```sh
  mix xcribe.doc -f swagger -o /home/user/api.doc
  ```

  You can generate doc for an specific endpoint by passing it as argument

  ```sh
  mix xcribe.doc -e YourAppWeb.Endpoint
  ```

  You can also pass options to Mix.Tasks.Test task. Ex to running an specific file
  to generate doc

  ```sh
  mix xcribe.doc test/you_app_web/controllers/users_controller_test.exs:20
  ```

  Note: to use this task you must configure `preferred_cli_env: ["xcribe.doc": :test]`
  on your `mix.ex` file.
  """
  use Mix.Task

  alias Xcribe.{CLI.Output, Config, Recorder}

  @requirements ["app.start"]

  @mix_test_opts ~w[--only xcribe_document --formatter Xcribe.Tasks.Formatter --max-failures 1]

  @shortdoc "Generate Xcribe documentation by running tests"

  @doc false
  def run(opts), do: run_task(opts)

  @doc false
  def run_task(opts, task_function \\ &run_mix_test_task/1, project_module \\ Mix.Project) do
    opts
    |> build_options(project_module)
    |> run_tests(task_function, project_module)
  end

  defp run_mix_test_task(opts), do: Mix.Task.run("test", opts)

  defp run_tests({:error, errors}, _task_function, _project_module) do
    Output.print_configuration_errors(errors)

    Output.print_message("Xcribe Task - aborted", :error)

    exit({:shutdown, 1})
  end

  defp run_tests({:ok, options}, task_function, project_module) do
    Recorder.set_active(true)
    Output.print_message("Xcribe Task - starting capture requests")

    task_function.(build_mix_test_opts(options))

    Output.print_message("Xcribe Task - starting doc generation")

    case Xcribe.document_all_records(override_configs(options, project_module)) do
      :ok ->
        Output.print_message("Xcribe Task - finished")
        :ok

      :error ->
        Output.print_message("Xcribe Task - aborted", :error)
        exit({:shutdown, 1})
    end
  end

  defp build_mix_test_opts(options) do
    additional_opts =
      options
      |> Map.get(:endpoint, [])
      |> List.wrap()
      |> Enum.concat(options.ignored)

    Enum.concat(@mix_test_opts, additional_opts)
  end

  defp override_configs(options, project_module) do
    if project_module.umbrella?() do
      fn endpoint, configs ->
        endpoint
        |> override_path_for_umbrella(configs, project_module)
        |> task_config_override(options)
      end
    else
      fn _endpoint, configs ->
        task_config_override(configs, options)
      end
    end
  end

  defp override_path_for_umbrella(endpoint, configs, project_module) do
    app_name = endpoint.config(:otp_app)

    case project_module.deps_paths()[app_name] do
      nil -> configs
      path -> %{configs | output: Path.join(path, configs.output)}
    end
  end

  defp task_config_override(configs, override) do
    Map.merge(configs, Map.take(override, [:output, :format]))
  end

  defp build_options(opts, project_module) do
    {options, rest, _invalid} =
      OptionParser.parse_head(opts,
        aliases: [o: :output, f: :format, e: :endpoint],
        strict: [output: :string, format: :string, endpoint: :string]
      )

    options
    |> Map.new()
    |> Map.put(:ignored, rest)
    |> validate_format()
    |> endpoint_path(project_module)
  end

  defp validate_format(%{format: format} = options) do
    Config.check_configurations(
      %{options | format: String.to_atom(format)},
      [:format]
    )
  end

  defp validate_format(options), do: {:ok, options}

  defp endpoint_path({:ok, %{endpoint: endpoint} = options}, project_module) do
    with module <- String.to_atom("Elixir.#{endpoint}"),
         true <- function_exported?(module, :config, 1),
         app_name <- module.config(:otp_app),
         path when is_binary(path) <- project_module.deps_paths()[app_name] do
      {:ok, %{options | endpoint: path}}
    else
      _any ->
        {:error, [{:endpoint, endpoint, "Couldn't find a path to endpoint #{endpoint}", ""}]}
    end
  end

  defp endpoint_path(options, _project_module), do: options
end
