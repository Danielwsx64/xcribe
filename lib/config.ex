defmodule Xcribe.Config do
  def output_file, do: Application.get_env(:xcribe, :output_file, "api_doc.apib")

  def api_format, do: Application.get_env(:xcribe, :doc_format, :api_blueprint)

  def active?, do: !is_nil(System.get_env(env_var_name()))

  def xcribe_information_source,
    do: Application.fetch_env!(:xcribe, :information_source)

  defp env_var_name, do: Application.get_env(:xcribe, :env_var, "XCRIBE_ENV")
end
