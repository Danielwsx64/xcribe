defmodule Xcribe.Helpers.Formatter do
  @moduledoc false

  @content_type_regex ~r/^(\w*\/[\w-]*(\.\w*\+\w*)?);?.*/
  @content_type_boundary_regex ~r/boundary=(.*);?/
  @doc """
  return the content type by a list of header params

  ### Options:
    * `default`: a value to be returned when not found content-type header.
  """
  def content_type(headers) when is_list(headers) do
    headers
    |> Enum.find_value(&find_content_type/1)
    |> handle_regex_match()
  end

  def content_type(_headers), do: nil

  @doc """
  return the content type boundary
  """

  def content_type_boundary(headers) when is_list(headers) do
    headers
    |> Enum.find_value(&find_content_type_boundary/1)
    |> handle_regex_match()
  end

  @doc """
  return the authorization header from a list of headers
  """
  def authorization(headers) when is_list(headers),
    do: Enum.reduce_while(headers, nil, &find_authorization/2)

  @doc """
  Format the path params.

      format_path_parameter("user_id")
      iex> "userId"
  """
  def format_path_parameter(name),
    do: " #{name}" |> Macro.camelize() |> String.replace_prefix(" ", "")

  defp find_content_type({"content-type", value}),
    do: Regex.run(@content_type_regex, value, capture: :all_but_first)

  defp find_content_type(_tuple), do: nil

  defp find_content_type_boundary({"content-type", value}),
    do: Regex.run(@content_type_boundary_regex, value, capture: :all_but_first)

  defp find_content_type_boundary(_tuple), do: nil

  defp find_authorization({"authorization", value}, _acc), do: {:halt, value}
  defp find_authorization(_header, _acc), do: {:cont, nil}

  defp handle_regex_match([value | _vnd_spec]), do: value
  defp handle_regex_match(value), do: value
end
