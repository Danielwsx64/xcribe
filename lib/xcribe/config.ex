defmodule Xcribe.Config do
  @moduledoc false

  alias Phoenix.ConnTest

  @valid_formats [:api_blueprint, :openapi]

  def default_spec_file, do: ".xcribe.exs"
  def active?, do: System.get_env("XCRIBE_ENV") in ["1", "true", "TRUE"]

  def server_port, do: Application.get_env(:xcribe, :server_port, 4040)
  def open_browser?, do: Application.get_env(:xcribe, :open_browser, false) in [true, "true"]

  def all_endpoints do
    :xcribe
    |> Application.get_all_env()
    |> Keyword.keys()
    |> Enum.filter(&valid_endpoint?/1)
  end

  def fetch_config(endpoint) when is_atom(endpoint) do
    :xcribe
    |> Application.get_env(endpoint, [])
    |> apply_default_values(endpoint)
  end

  def get_serving_path(%{file_path: {_static, path}, file_name: file}) do
    Path.join([path, file])
  end

  def get_serving_path(%{file_name: file}), do: file

  def get_output_path(%{file_path: path} = config) when is_tuple(path) do
    get_output_path(%{config | file_path: Tuple.to_list(path)})
  end

  def get_output_path(%{file_name: file_name} = config) do
    config
    |> Map.get(:file_path, [])
    |> List.wrap()
    |> Enum.concat([file_name])
    |> Path.join()
  end

  @default_keys_to_validate [:format, :specification_source, :json_library, :serve]
  def check_configurations(config, keys \\ @default_keys_to_validate) do
    case Enum.reduce(keys, {:ok, config}, &validate_config/2) do
      {:ok, config} -> {:ok, config}
      {{:error, _list} = err, _config} -> err
    end
  end

  @format_message "Xcribe doesn't support the configured documentation format"
  @format_instructions "Xcribe supports :openapi and :api_blueprint, configure as: `config :xcribe, Endpoint, format: :openapi`. The :swagger format was renamed to :openapi."
  defp validate_config(:format, {_errors, config} = results) do
    format = Map.fetch!(config, :format)

    if format in @valid_formats do
      results
    else
      add_error(results, :format, format, @format_message, @format_instructions)
    end
  end

  @spec_file_message "The configured specification file doesn't exist"
  @spec_file_instructions "Add a valid spec file path in `config :xcribe, Endpoint, specification_source: \".xcribe.exs\"`"
  defp validate_config(:specification_source, {_errors, config} = results) do
    file = Map.fetch!(config, :specification_source)

    if file == default_spec_file() or File.exists?(file) do
      results
    else
      add_error(results, :specification_source, file, @spec_file_message, @spec_file_instructions)
    end
  end

  @json_lib_message "The configured json library doesn't implement the needed functions"
  @json_lib_instructions "Try configure Xcribe with Jason or Poison `config :xcribe, Endpoint, json_library: Jason`"
  defp validate_config(:json_library, {_errors, config} = results) do
    lib = Map.fetch!(config, :json_library)

    if function_exported?(lib, :decode!, 2) do
      results
    else
      add_error(results, :json_library, lib, @json_lib_message, @json_lib_instructions)
    end
  end

  defp validate_config(:serve, {_errors, config} = results) do
    if Map.fetch!(config, :serve) do
      results
      |> validate_serve_format()
      |> validate_serve_output()
    else
      results
    end
  end

  @serve_format_message "When serve config is true you must use the :openapi format"
  @serve_format_instructions "You must use the OpenAPI format: `config :xcribe, Endpoint, format: :openapi`"
  defp validate_serve_format({_errors, config} = results) do
    format = Map.fetch!(config, :format)

    if format == :openapi do
      results
    else
      add_error(results, :format, format, @serve_format_message, @serve_format_instructions)
    end
  end

  @serve_output_message "When serve config is true your Endpoint must be able to serve the generated document, but a request for it didn't return the file"
  @serve_output_instructions "Make file_path and file_name match a Plug.Static in your Endpoint — the directory it serves and its `only:` allow list: `config :xcribe, Endpoint, file_path: {\"priv/static\", \"api\"}, file_name: \"openapi.json\"`"
  defp validate_serve_output({_errors, config} = results) do
    endpoint = Map.fetch!(config, :endpoint)
    serving_path = get_serving_path(config)

    Code.ensure_loaded(endpoint)
    config |> get_output_path() |> File.touch()

    Path.join(["/", serving_path])
    |> then(&ConnTest.build_conn(:get, &1))
    |> call_endpoint(endpoint)
    |> case do
      %{status: 200} ->
        results

      _not_found_or_error ->
        add_error(
          results,
          :file_path,
          serving_path,
          @serve_output_message,
          @serve_output_instructions
        )
    end
  end

  defp call_endpoint(path, endpoint) do
    endpoint.call(path, [])
  rescue
    _any ->
      {:error, "failed to call endpoint"}
  end

  defp add_error({:ok, config}, key, value, msg, info) do
    {{:error, [{key, value, msg, info}]}, config}
  end

  defp add_error({{:error, errs}, config}, key, value, msg, info) do
    {{:error, [{key, value, msg, info} | errs]}, config}
  end

  defp apply_default_values(keyword, endpoint) do
    format = Keyword.get(keyword, :format, :openapi)
    json_library = Keyword.get(keyword, :json_library, Jason)
    file_path = Keyword.get(keyword, :file_path)
    file_name = Keyword.get(keyword, :file_name, default_output(format))
    serve = Keyword.get(keyword, :serve, false)
    specification_source = Keyword.get(keyword, :specification_source, default_spec_file())

    %{
      endpoint: endpoint,
      format: format,
      json_library: json_library,
      file_path: file_path,
      file_name: file_name,
      serve: serve,
      specification_source: specification_source
    }
  end

  defp default_output(format) do
    case format do
      :api_blueprint -> "api_doc.apib"
      :openapi -> "openapi.json"
      _ -> ""
    end
  end

  defp valid_endpoint?(module) do
    Code.ensure_loaded(module)
    function_exported?(module, :config, 1)
  end
end
