defmodule Xcribe.Config do
  @moduledoc false

  @valid_formats [:api_blueprint, :swagger]

  def default_spec_file, do: ".xcribe.exs"
  def active?, do: System.get_env("XCRIBE_ENV") in ["1", "true", "TRUE"]

  def fetch_config(endpoint) when is_atom(endpoint) do
    :xcribe
    |> Application.get_env(endpoint, [])
    |> apply_default_values()
  end

  def all_endpoints do
    :xcribe
    |> Application.get_all_env()
    |> Keyword.keys()
    |> Enum.filter(&valid_endpoint?/1)
  end

  @default_keys_to_validate [:format, :specification_source, :json_library, :serve]
  def check_configurations(config, keys \\ @default_keys_to_validate) do
    case Enum.reduce(keys, {:ok, config}, &validate_config/2) do
      {:ok, config} -> {:ok, config}
      {{:error, _list} = err, _config} -> err
    end
  end

  @format_message "Xcribe doesn't support the configured documentation format"
  @format_instructions "Xcribe supports Swagger and Blueprint, configure as: `config :xcribe, Endpoint, format: :swagger`"
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

  @serve_format_message "When serve config is true you must use swagger format"
  @serve_format_instructions "You must use Swagger format: `config :xcribe, Endpoint, format: :swagger`"
  defp validate_serve_format({_errors, config} = results) do
    format = Map.fetch!(config, :format)

    if format == :swagger do
      results
    else
      add_error(results, :format, format, @serve_format_message, @serve_format_instructions)
    end
  end

  @serve_output_message "When serve config is true you must confiture output to \"priv/static\" folder"
  @serve_output_instructions "You must configure output as: `config :xcribe, Endpoint, output: \"priv/static/doc.json\"`"
  defp validate_serve_output({_errors, config} = results) do
    output = Map.fetch!(config, :output)

    if Regex.match?(~r'priv\/static\/[\.\w-]+$', output) do
      results
    else
      add_error(results, :output, output, @serve_output_message, @serve_output_instructions)
    end
  end

  defp add_error({:ok, config}, key, value, msg, info) do
    {{:error, [{key, value, msg, info}]}, config}
  end

  defp add_error({{:error, errs}, config}, key, value, msg, info) do
    {{:error, [{key, value, msg, info} | errs]}, config}
  end

  defp apply_default_values(keyword) do
    format = Keyword.get(keyword, :format, :swagger)
    json_library = Keyword.get(keyword, :json_library, Jason)
    output = Keyword.get(keyword, :output, default_output(format))
    serve = Keyword.get(keyword, :serve, false)
    specification_source = Keyword.get(keyword, :specification_source, default_spec_file())

    %{
      format: format,
      json_library: json_library,
      output: output,
      serve: serve,
      specification_source: specification_source
    }
  end

  defp default_output(format) do
    case format do
      :api_blueprint -> "api_doc.apib"
      :swagger -> "openapi.json"
      _ -> ""
    end
  end

  defp valid_endpoint?(module) do
    function_exported?(module, :config, 1)
  end
end
