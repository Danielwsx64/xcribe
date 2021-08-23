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
    content_type
    |> define_format()
    |> decode_for(value, config)
  end

  defp define_format(content_type) do
    cond do
      is_json?(content_type) -> :json
      is_text_plain?(content_type) -> :string
      true -> raise UnknownType, content_type
    end
  end

  defp decode_for(:json, value, config), do: JSON.decode!(value, [], config)
  defp decode_for(:string, value, _config), do: to_string(value)

  defp is_json?(type), do: Regex.match?(@json_format_regex, type)
  defp is_text_plain?(type), do: Regex.match?(@text_plain_format_regex, type)
end
