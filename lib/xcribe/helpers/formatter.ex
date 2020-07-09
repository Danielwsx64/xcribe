defmodule Xcribe.Helpers.Formatter do
  @moduledoc false

  @content_type_regex ~r{^(\w*\/\w*(\.\w*\+\w*)?);?.*}

  @doc """
  return the content type by a list of header params

  ### Options:
    * `default`: a value to be returned when not found content-type header.
  """
  def content_type(headers, opts \\ []) when is_list(headers) do
    Enum.reduce_while(headers, Keyword.get(opts, :default), &find_content_type/2)
  end

  @doc """
  return the authorization header from a list of headers
  """
  def authorization(headers) when is_list(headers) do
    Enum.reduce_while(headers, nil, &find_authorization/2)
  end

  @doc """
  Format the path params.

      format_path_parameter("user_id")
      iex> "userId"
  """
  def format_path_parameter(name),
    do: " #{name}" |> Macro.camelize() |> String.replace_prefix(" ", "")

  defp find_content_type({"content-type", value}, _default) do
    @content_type_regex
    |> Regex.run(value, capture: :all_but_first)
    |> handle_content_type_regex()
  end

  defp find_content_type(_header, default), do: {:cont, default}

  defp find_authorization({"authorization", value}, _acc), do: {:halt, value}
  defp find_authorization(_header, _acc), do: {:cont, nil}

  defp handle_content_type_regex(nil), do: {:halt, nil}
  defp handle_content_type_regex([content_type]), do: {:halt, content_type}
  defp handle_content_type_regex([content_type | _vnd_spec]), do: {:halt, content_type}
end
