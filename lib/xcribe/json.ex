defmodule Xcribe.JSON do
  @moduledoc false

  alias Xcribe.Config

  @doc """
  wrapper for json library encode function
  """
  def encode(value, options \\ []) do
    json_library().encode(value, options)
  end

  @doc """
  wrapper for json library encode! function
  """
  def encode!(value, options \\ []) do
    json_library().encode!(value, options)
  end

  @doc """
  wrapper for json library decode function
  """
  def decode(value, options \\ []) do
    json_library().decode(value, options)
  end

  @doc """
  wrapper for json library decode! function
  """
  def decode!(value, options \\ []) do
    json_library().decode!(value, options)
  end

  defp json_library, do: Config.fetch(:json_library)
end
