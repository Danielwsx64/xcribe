defmodule Xcribe.Config do
  @valid_formats [:api_blueprint, :swagger]
  def output_file, do: Application.get_env(:xcribe, :output_file, default_output_file())

  def doc_format do
    :xcribe
    |> Application.get_env(:doc_format, :api_blueprint)
    |> validate_doc_format()
  end

  def active?, do: !is_nil(System.get_env(env_var_name()))

  def xcribe_information_source,
    do: Application.fetch_env!(:xcribe, :information_source)

  defp env_var_name, do: Application.get_env(:xcribe, :env_var, "XCRIBE_ENV")

  defp default_output_file() do
    case doc_format() do
      :api_blueprint -> "api_doc.apib"
      :swagger -> "openapi.json"
      _ -> ""
    end
  end

  defp validate_doc_format(format) when format in @valid_formats, do: format
  defp validate_doc_format(_), do: :error
end
