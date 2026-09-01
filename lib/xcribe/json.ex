defmodule Xcribe.JSON do
  @moduledoc false

  @doc """
  wrapper for json library encode! function

  Keys are normalized to strings before encoding. Maps with atom keys iterate in
  atom-table order, which is arbitrary and varies between Elixir/OTP releases, so
  encoding them directly produces documentation whose key order changes for no
  reason. String keys iterate in term order, which keeps the generated output
  stable across runs and releases.
  """
  def encode!(value, options, %{json_library: json_library}) do
    value
    |> stringify_keys()
    |> json_library.encode!(options)
  end

  @doc """
  wrapper for json library decode! function
  """
  def decode!(value, options, %{json_library: json_library}) do
    json_library.decode!(value, options)
  end

  defp stringify_keys(%_struct{} = value), do: value

  defp stringify_keys(value) when is_map(value) do
    Map.new(value, fn {key, val} -> {to_string(key), stringify_keys(val)} end)
  end

  defp stringify_keys(value) when is_list(value), do: Enum.map(value, &stringify_keys/1)

  defp stringify_keys(value), do: value
end
