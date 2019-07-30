defmodule Xcribe.Config do
  def output_file, do: Application.get_env(:xcribe, :output_file, "api_doc.apib")

  def active?, do: !is_nil(System.get_env(env_var_name()))

  defp env_var_name, do: Application.get_env(:xcribe, :env_var, "XCRIBE_ENV")
end
