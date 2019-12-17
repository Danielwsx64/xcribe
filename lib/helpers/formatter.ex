defmodule Xcribe.Helpers.Formatter do
  alias Xcribe.JSON

  @arguments_regex ~r/({\w*})/
  @ending_arg_regex ~r/{(\w*)}$/
  @non_word_regex ~r/\W/
  @mult_spaces_regex ~r/\s+/
  @slash_regex ~r/\/$/
  @path_ending_arg_regex ~r/({\w*}\/$)/

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

  def find_content_type(nil), do: "text/plain"
  def find_content_type(headers), do: Enum.reduce(headers, "text/plain", &find_content_header/2)

  def format_body(body, "application/json" <> _) when is_binary(body),
    do: body |> JSON.decode!() |> format_body("application/json")

  def format_body(body, "application/json" <> _) when is_map(body) or is_list(body),
    do: body |> JSON.encode!(pretty: true)

  def format_body(body, "text/plain" <> _) when is_binary(body),
    do: body

  defp find_content_header({"content-type", type}, _acc), do: type
  defp find_content_header(_, acc), do: acc

  defp unify_matchs(nil), do: []
  defp unify_matchs(matchs), do: Enum.uniq(matchs)

  defp replace_params(param, path), do: String.replace(path, param, camelize(param))
end
