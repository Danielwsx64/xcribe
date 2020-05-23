defmodule Xcribe.Swagger.Types do
  @moduledoc false

  @doc ~S"""
  Return the type of given data
  """
  def type_for(data) when is_number(data), do: "number"
  def type_for(data) when is_binary(data), do: "string"
  def type_for(data) when is_boolean(data), do: "boolean"
  def type_for(_), do: "string"

  @doc ~S"""
  Return the format of given data
  """
  def format_for(data) when is_float(data), do: "float"
  def format_for(data) when is_integer(data), do: "int32"
  def format_for(_), do: ""
end
