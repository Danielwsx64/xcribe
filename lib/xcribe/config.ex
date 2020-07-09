defmodule Xcribe.Config do
  @moduledoc false

  alias Xcribe.{MissingInformationSource, UnknownFormat}

  @valid_formats [:api_blueprint, :swagger]

  @doc """
  Return true if serve mode is enabled.

  If no config was given the default is false.

  To configure server mode:

      config :xcribe, [
        serve: true
      ]
  """
  def serving?, do: get_xcribe_config(:serve, false) == true

  @doc """
  Return the file name to output generated documentation.

  If no config was given the default names are `api_doc.apib` for Blueprint
  format and `openapi.json` for Swagger format.

  To configure output name:

      config :xcribe, [
        output: "custom_name.json"
      ]
  """
  def output_file, do: get_xcribe_config(:output, default_output_file())

  @doc """
  Return the format for documentation.

  Default is `:api_blueprint`. 

  To configure the documentation format:

      config :xcribe, [
        format: :swagger
      ]
  """
  def doc_format, do: get_xcribe_config(:format, :api_blueprint)

  @doc """
  Return the format for documentation.

  Default is `:api_blueprint`. If an invalid format is given an `Xcribe.UnknownFormat`
  exception will raise.
  """
  def doc_format!, do: :format |> get_xcribe_config(:api_blueprint) |> validate_doc_format()

  @doc """
  Return if Xcribe should document the specs.

  It's determined by an env var `XCRIBE_ENV`. Don't matter the var content if
  it's defined Xcribe will generate documentation.

  The env var name can changed by configuration:

      config :xcribe, [
        env_var: "CUSTOM_ENV_NAME"
      ]
  """
  def active?, do: !is_nil(System.get_env(env_var_name()))

  @doc """
  Return the information module with API information

  To configure the source:

      config :xcribe, [
        information_source: YourApp.YouModuleInformation
      ]
  """
  def xcribe_information_source, do: get_xcribe_config(:information_source)

  @doc """
  Return the information module with API information

  If information source is not given an `Xcribe.MissingInformationSource` exception will raise.
  """
  def xcribe_information_source! do
    case get_xcribe_config(:information_source) do
      nil -> raise MissingInformationSource
      information_source -> information_source
    end
  end

  @doc """
  Return configured json library.

  If no custom lib was configured the `Phoenix` configuration will be used.

  To configure:

      config :xcribe, [
        json_library: Jason
      ]

  """
  def json_library, do: get_xcribe_config(:json_library, Phoenix.json_library())

  @doc """
  Return ok if given configurations are valid.

  If same invalid config was set an tuple with a list of erros will be returned.
  """
  def check_configurations(configs \\ [:format, :information_source, :json_library, :serve]),
    do: Enum.reduce(configs, :ok, &validate_config/2)

  @format_message "Xcribe doesn't support the configured documentation format"
  @format_instructions "Xcribe supports Swagger and Blueprint, configure as: `config :xcribe, format: :swagger`"
  defp validate_config(:format, results) do
    format = doc_format()

    if format in @valid_formats do
      results
    else
      add_error(results, :format, format, @format_message, @format_instructions)
    end
  end

  @info_source_message "The configured module as information source is not using Xcribe macros"
  @info_source_instructions "Add `use Xcribe, :information` on top of your module"
  defp validate_config(:information_source, results) do
    module = xcribe_information_source()

    if {:api_info, 0} in module_functions(module) do
      results
    else
      add_error(
        results,
        :information_source,
        module,
        @info_source_message,
        @info_source_instructions
      )
    end
  end

  @json_lib_message "The configured json library doesn't implement the needed functions"
  @json_lib_instructions "Try configure Xcribe with Jason or Poison `config :xcribe, json_library: Jason`"
  defp validate_config(:json_library, results) do
    lib = json_library()

    if function_exported?(lib, :decode!, 2) do
      results
    else
      add_error(results, :json_library, lib, @json_lib_message, @json_lib_instructions)
    end
  end

  defp validate_config(:serve, results) do
    if serving?() do
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
    format = doc_format()

    if format == :swagger do
      results
    else
      add_error(
        results,
        :format,
        format,
        @serve_format_message,
        @serve_format_instructions
      )
    end
  end

  @serve_output_message "When serve config is true you must confiture output to \"priv/static\" folder"
  @serve_output_instructions "You must configure output as: `config :xcribe, output: \"priv/static/doc.json\"`"
  defp validate_serve_output(results) do
    output = output_file()

    if Regex.match?(~r/^priv\/static\/.*/, output) do
      results
    else
      add_error(
        results,
        :output,
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

  defp env_var_name, do: get_xcribe_config(:env_var, "XCRIBE_ENV")

  defp validate_doc_format(format) when format in @valid_formats, do: format
  defp validate_doc_format(format), do: raise(UnknownFormat, format)

  defp default_output_file do
    case doc_format() do
      :api_blueprint -> "api_doc.apib"
      :swagger -> "openapi.json"
      _ -> ""
    end
  end

  defp get_xcribe_config(key, default \\ nil),
    do: Application.get_env(:xcribe, key, default)
end
