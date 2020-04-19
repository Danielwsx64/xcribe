defmodule Xcribe.JSON do
  @moduledoc """
  Wrapper for a JSON library.

  Poison and Jason are the most popular json libraries common used in Elixir
  projects. Xcribe works with both. By default Xcribe use the same library as
  Phoenix. But you can change it by config.
  """

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

  defp json_library, do: Jason
end
