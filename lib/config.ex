defmodule Xcribe.Config do
  @moduledoc false

  alias Xcribe.{MissingInformationSource, UnknownFormat}

  @valid_formats [:api_blueprint, :swagger]

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

  Default is `:api_blueprint`. If an invalid format is given an `Xcribe.UnknownFormat`
  exception will raise.

  To configure the documentation format:

      config :xcribe, [
        format: :swagger
      ]
  """
  def doc_format do
    :format
    |> get_xcribe_config(:api_blueprint)
    |> validate_doc_format()
  end

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
  Return the iformation module with API information (`Xcribe.Information`).

  If information source is not given an `Xcribe.MissingInformationSource` exception will raise.

  To configure the source:

      config :xcribe, [
        information_source: YourApp.YouModuleInformation
      ]
  """
  def xcribe_information_source do
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

  defp env_var_name, do: get_xcribe_config(:env_var, "XCRIBE_ENV")

  defp default_output_file do
    case doc_format() do
      :api_blueprint -> "api_doc.apib"
      :swagger -> "openapi.json"
    end
  end

  defp validate_doc_format(format) when format in @valid_formats, do: format
  defp validate_doc_format(format), do: raise(UnknownFormat, format)

  defp get_xcribe_config(key, default \\ nil) do
    cond do
      value = new_config(key) -> value
      value = old_config(key) -> value
      true -> default
    end
  end

  defp new_config(key), do: Application.get_env(:xcribe, key)

  defp old_config(key), do: Application.get_env(:xcribe, rename_key(key))

  defp rename_key(:output), do: :output_file
  defp rename_key(:format), do: :doc_format
  defp rename_key(key), do: key
end
