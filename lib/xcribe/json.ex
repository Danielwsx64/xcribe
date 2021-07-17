defmodule Xcribe.JSON do
  @moduledoc false

  @doc """
  wrapper for json library encode function
  """
  def encode(value, options, %{json_library: json_library}) do
    json_library.encode(value, options)
  end

  @doc """
  wrapper for json library encode! function
  """
  def encode!(value, options, %{json_library: json_library}) do
    json_library.encode!(value, options)
  end

  @doc """
  wrapper for json library decode function
  """
  def decode(value, options, %{json_library: json_library}) do
    json_library.decode(value, options)
  end

  @doc """
  wrapper for json library decode! function
  """
  def decode!(value, options, %{json_library: json_library}) do
    json_library.decode!(value, options)
  end
end
