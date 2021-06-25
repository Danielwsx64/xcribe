defmodule Xcribe.Config do
  @moduledoc false
  use GenServer

  alias Xcribe.{MissingInformationSource, UnknownFormat}

  @valid_formats [:api_blueprint, :swagger]

  @config_keys %{
    active?: :active?,
    doc_format: :format,
    env_var: :env_var,
    json_library: :json_library,
    output_file: :output,
    serving?: :serve,
    xcribe_information_source: :information_source
  }

  @config_default_values %{
    active?: &__MODULE__.default_value/1,
    doc_format: :swagger,
    output_file: &__MODULE__.default_value/1,
    json_library: Jason,
    env_var: "XCRIBE_ENV"
  }

  def start_link(opts \\ []),
    do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  def init(opts), do: {:ok, Keyword.get(opts, :override, %{})}

  def override(key, value), do: GenServer.call(__MODULE__, {:override, key, value})

  def clear_override, do: GenServer.call(__MODULE__, :clear_override)

  def fetch!(config) do
    config
    |> fetch()
    |> validate(config)
  end

  def fetch(:serving?), do: get_xcribe_config(:serving?) == true

  def fetch(config) do
    case fetch_override(config) do
      :override_not_found -> get_xcribe_config(config)
      override -> override
    end
  end

  def handle_call(:clear_override, _from, _override), do: {:reply, :ok, %{}}

  def handle_call({:override, key, value}, _from, override),
    do: {:reply, :ok, Map.put(override, key, value)}

  def handle_call({:fetch_override, config}, _from, override),
    do: {:reply, Map.get(override, config, :override_not_found), override}

  def check_configurations(
        configs \\ [:doc_format, :xcribe_information_source, :json_library, :serving?]
      ),
      do: Enum.reduce(configs, :ok, &validate_config/2)

  def default_value(:output_file) do
    case fetch(:doc_format) do
      :api_blueprint -> "api_doc.apib"
      :swagger -> "openapi.json"
      _ -> ""
    end
  end

  def default_value(:active?), do: !is_nil(System.get_env(fetch(:env_var)))

  defp fetch_override(config), do: GenServer.call(__MODULE__, {:fetch_override, config})

  @format_message "Xcribe doesn't support the configured documentation format"
  @format_instructions "Xcribe supports Swagger and Blueprint, configure as: `config :xcribe, format: :swagger`"
  defp validate_config(:doc_format, results) do
    format = fetch(:doc_format)

    if format in @valid_formats do
      results
    else
      add_error(
        results,
        config_key!(:doc_format),
        format,
        @format_message,
        @format_instructions
      )
    end
  end

  @info_source_message "The configured module as information source is not using Xcribe macros"
  @info_source_instructions "Add `use Xcribe, :information` on top of your module"
  defp validate_config(:xcribe_information_source, results) do
    module = fetch(:xcribe_information_source)

    if {:api_info, 0} in module_functions(module) do
      results
    else
      add_error(
        results,
        config_key!(:xcribe_information_source),
        module,
        @info_source_message,
        @info_source_instructions
      )
    end
  end

  @json_lib_message "The configured json library doesn't implement the needed functions"
  @json_lib_instructions "Try configure Xcribe with Jason or Poison `config :xcribe, json_library: Jason`"
  defp validate_config(:json_library, results) do
    lib = fetch(:json_library)

    if function_exported?(lib, :decode!, 2) do
      results
    else
      add_error(
        results,
        config_key!(:json_library),
        lib,
        @json_lib_message,
        @json_lib_instructions
      )
    end
  end

  defp validate_config(:serving?, results) do
    if fetch(:serving?) do
      results
      |> validate_serve_format()
      |> validate_serve_output()
    else
      results
    end
  end

  @serve_format_message "When serve config is true you must use swagger format"
  @serve_format_instructions "You must use Swagger format: `config :xcribe, format: :swagger`"
  defp validate_serve_format(results) do
    format = fetch(:doc_format)

    if format == :swagger do
      results
    else
      add_error(
        results,
        config_key!(:doc_format),
        format,
        @serve_format_message,
        @serve_format_instructions
      )
    end
  end

  @serve_output_message "When serve config is true you must confiture output to \"priv/static\" folder"
  @serve_output_instructions "You must configure output as: `config :xcribe, output: \"priv/static/doc.json\"`"
  defp validate_serve_output(results) do
    output = fetch(:output_file)

    if Regex.match?(~r/^priv\/static\/.*/, output) do
      results
    else
      add_error(
        results,
        config_key!(:output_file),
        output,
        @serve_output_message,
        @serve_output_instructions
      )
    end
  end

  defp module_functions(module) do
    apply(module, :__info__, [:functions])
  rescue
    UndefinedFunctionError -> []
  end

  defp add_error(:ok, key, value, msg, info), do: {:error, [{key, value, msg, info}]}

  defp add_error({:error, errs}, key, value, msg, info),
    do: {:error, [{key, value, msg, info} | errs]}

  defp validate(format, :doc_format) when format not in @valid_formats,
    do: raise(UnknownFormat, format)

  defp validate(nil, :xcribe_information_source), do: raise(MissingInformationSource)

  defp validate(value, _config), do: value

  defp get_xcribe_config(config) do
    Application.get_env(:xcribe, config_key!(config), get_default(config))
  end

  defp config_key!(config), do: Map.fetch!(@config_keys, config)

  defp get_default(config) do
    case Map.get(@config_default_values, config) do
      func when is_function(func) -> func.(config)
      value -> value
    end
  end
end
