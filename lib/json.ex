defmodule Xcribe.JSON do
  def encode(value, options \\ []) do
    json_library().encode(value, options)
  end

  def encode!(value, options \\ []) do
    json_library().encode!(value, options)
  end

  def decode(value, options \\ []) do
    json_library().decode(value, options)
  end

  def decode!(value, options \\ []) do
    json_library().decode!(value, options)
  end

  defp json_library, do: Jason
end
