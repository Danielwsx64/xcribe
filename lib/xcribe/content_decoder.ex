defmodule Xcribe.ContentDecoder do
  @moduledoc false

  alias Xcribe.ContentDecoder.UnknownType
  alias Xcribe.JSON

  @json_format_regex ~r{application\/json|application\/vnd\..*json}
  @text_plain_format_regex ~r{text\/plain}

  @doc """
  Decode value by the given content_type.

      iex> ContentDecoder.decode!("{\"key\":\"value\"}", "application/json", %{json_library: Jason})
      %{"key" => "value"}

  An UnknownType excption is raised when given content_type is unknown.
  """
  def decode!(value, content_type, config) do
    value
    |> decode(content_type, config)
    |> handle_decode!()
  end

  @doc """
  Decode value by the given content_type answering a tagged tuple.

  Unlike `decode!/3` an unknown content type is returned as data, so a caller that documents
  whatever the application answered can keep the undecodable value instead of failing.
  """
  def decode(value, content_type, config) do
    content_type
    |> define_format()
    |> decode_for(value, config)
  end

  defp define_format(content_type) do
    cond do
      json?(content_type) -> :json
      text_plain?(content_type) -> :string
      true -> {:error, {:unknown_content_type, content_type}}
    end
  end

  defp decode_for(:json, value, config), do: {:ok, JSON.decode!(value, [], config)}
  defp decode_for(:string, value, _config), do: {:ok, to_string(value)}
  defp decode_for({:error, _reason} = error, _value, _config), do: error

  defp handle_decode!({:ok, decoded}), do: decoded

  defp handle_decode!({:error, {:unknown_content_type, content_type}}),
    do: raise(UnknownType, content_type)

  defp json?(type), do: Regex.match?(@json_format_regex, type)
  defp text_plain?(type), do: Regex.match?(@text_plain_format_regex, type)
end
