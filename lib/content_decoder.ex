defmodule Xcribe.ContentDecoder do
  @moduledoc false

  alias Xcribe.ContentDecoder.UnknownType
  alias Xcribe.JSON

  @json_format_regex ~r{application\/json|application\/vnd\..*json}

  @doc """
  Decode value by the given content_type.

      iex> ContentDecoder.decode!("{\"key\":\"value\"}", "application/json")
      %{"key" => "value"}

  An UnknownType excption is raised when given content_type is unknown.
  """
  def decode!(value, content_type) do
    content_type
    |> define_format()
    |> decode_for(value)
  end

  defp decode_for(:json, value), do: JSON.decode!(value)

  defp define_format(content_type) do
    if is_json?(content_type) do
      :json
    else
      raise UnknownType, content_type
    end
  end

  defp is_json?(content_type), do: Regex.match?(@json_format_regex, content_type)
end
