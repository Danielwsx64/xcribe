defmodule Xcribe.Helpers.Formatter do
  @moduledoc ~S"""
  This module implements a set of useful functions for formatter modules.
  """

  alias Xcribe.JSON

  @arguments_regex ~r/({\w*})/
  @ending_arg_regex ~r/{(\w*)}$/
  @non_word_regex ~r/\W/
  @mult_spaces_regex ~r/\s+/
  @slash_regex ~r/\/$/
  @path_ending_arg_regex ~r/({\w*}\/$)/
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
  def format_path_parameter(name) do
    " #{name}" |> Macro.camelize() |> String.replace_prefix(" ", "")
  end

  def prepare_and_upcase(string), do: string |> remove_underline() |> String.upcase()

  def prepare_and_captalize(string), do: string |> remove_underline() |> capitalize()

  def remove_underline(text) when is_binary(text), do: String.replace(text, "_", " ")

  def remove_underline(text) when is_atom(text),
    do: text |> Atom.to_string() |> remove_underline()

  def remove_underline(text), do: text

  def capitalize(string),
    do: string |> String.split() |> Enum.map(&String.capitalize/1) |> Enum.join(" ")

  def apply_template(template, keyword),
    do: Enum.reduce(keyword, template, &replace_template/2)

  def replace_template({key, value}, template),
    do: String.replace(template, "--#{key}--", value)

  def camelize(string), do: Macro.camelize(string)

  def camelize_params(path) do
    @arguments_regex
    |> Regex.run(path)
    |> unify_matchs()
    |> Enum.reduce(path, &replace_params/2)
  end

  def path_ending_arg(path) when is_binary(path) do
    case Regex.run(@ending_arg_regex, path) do
      [_, arg] -> arg
      _ -> nil
    end
  end

  def path_ending_arg(_path), do: nil

  def type_of(item) when is_number(item), do: "number"
  def type_of(item) when is_binary(item), do: "string"
  def type_of(item) when is_boolean(item), do: "boolean"
  def type_of(item) when is_map(item), do: "object"
  def type_of(item) when is_list(item), do: "array"

  def purge_string(string),
    do: string |> String.replace(@non_word_regex, " ") |> String.replace(@mult_spaces_regex, " ")

  def fetch_key(map, key, default) when is_list(map),
    do: fetch_key(Enum.into(map, %{}), key, default)

  def fetch_key(map, key, default) do
    case Map.fetch(map, key) do
      {:ok, value} -> value
      _ -> default
    end
  end

  def ident_lines(text, count) do
    text
    |> String.split("\n")
    |> Enum.map(fn l -> if(l == "", do: "", else: apply_tab(l, count)) end)
    |> Enum.join("\n")
  end

  def tab(count), do: apply_tab("", count)

  def apply_tab(text, count), do: 1..count |> Enum.reduce(text, &concat_tab/2)

  def concat_tab(_count, text), do: "    " <> text

  def add_forward_slash(path),
    do: if(Regex.match?(@slash_regex, path), do: path, else: "#{path}/")

  def remove_ending_argument(path) do
    case Regex.run(@path_ending_arg_regex, path) do
      nil -> path
      [capture | _] -> String.replace(path, capture, "")
    end
  end

  def format_body(body, "application/json" <> _) when is_binary(body),
    do: body |> JSON.decode!() |> format_body("application/json")

  def format_body(body, "application/json" <> _) when is_map(body) or is_list(body),
    do: body |> JSON.encode!(pretty: true)

  def format_body(body, "text/plain" <> _) when is_binary(body),
    do: body

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

  defp unify_matchs(nil), do: []
  defp unify_matchs(matchs), do: Enum.uniq(matchs)

  defp replace_params(param, path), do: String.replace(path, param, camelize(param))
end
