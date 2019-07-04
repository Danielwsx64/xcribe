defmodule Xcribe.ApiBlueprint.Formatter do
  alias Xcribe.JSON

  def resource_group(%{resource_group: name}),
    do: "## Group " <> String.upcase("#{name}\n")

  def resource(%{resource: resource, path: path}),
    do: "## #{capitalize(resource)} #{build_resource_path(path)}\n"

  def resource_action(%{resource: resource, path: path, action: action, verb: verb}),
    do: "### #{capitalize(resource)} #{action} #{build_resource_path(path, verb)}\n"

  def full_request(struct) do
    [
      request_description(struct),
      request_headers(struct),
      request_body(struct),
      "\n",
      response_description(struct),
      response_headers(struct),
      response_body(struct)
    ]
    |> Enum.join()
  end

  def request_description(%{description: description, header_params: headers}),
    do: "+ Request #{description} (#{find_content_type(headers)})\n"

  def request_headers(%{header_params: []}), do: ""
  def request_headers(%{header_params: headers}), do: headers_section(headers)

  def response_headers(%{resp_headers: []}), do: ""
  def response_headers(%{resp_headers: headers}), do: headers_section(headers)

  def request_body(%{request_body: body}) when body == %{}, do: ""
  def request_body(%{request_body: body}), do: body_section(body)

  def response_body(%{resp_body: body}) when body == %{}, do: ""
  def response_body(%{resp_body: body}), do: body_section(body)

  def response_description(%{status_code: code, resp_headers: headers}),
    do: "+ Response #{code} (#{find_content_type(headers)})\n"

  defp find_content_type(nil), do: "text/plain"

  defp find_content_type(headers) do
    headers
    |> Enum.reduce("text/plain", &find_content_type_header/2)
  end

  defp find_content_type_header({"content-type", type}, _acc), do: type
  defp find_content_type_header(_, acc), do: acc

  defp headers_section(headers) do
    title = "+ Headers\n\n" |> apply_tab(1)
    headers = format_headers(headers)

    if headers == "", do: "", else: title <> headers
  end

  def body_section(body) do
    title = "+ Body\n\n" |> apply_tab(1)
    body = format_body(body)

    title <> body <> "\n"
  end

  defp capitalize(string) do
    string
    |> String.split()
    |> Enum.map(&String.capitalize/1)
    |> Enum.join(" ")
  end

  defp build_resource_path(path, verb \\ nil)

  defp build_resource_path(path, verb) do
    path
    |> add_forward_slash()
    |> remove_ending_argument()
    |> into_brackets(verb)
  end

  defp add_forward_slash(path),
    do: if(Regex.match?(~r/\/$/, path), do: path, else: "#{path}/")

  defp into_brackets(path, nil), do: "[#{path}]"
  defp into_brackets(path, verb), do: "[#{String.upcase(verb)} #{path}]"

  defp remove_ending_argument(path) do
    case Regex.run(~r/({\w*}\/$)/, path) do
      nil -> path
      [capture | _] -> String.replace(path, capture, "")
    end
  end

  defp ident_lines(text, count) do
    text
    |> String.split("\n")
    |> Enum.map(&apply_tab(&1, count))
    |> Enum.join("\n")
  end

  defp apply_tab(text, count),
    do: 1..count |> Enum.reduce(text, &concat_tab/2)

  defp concat_tab(_count, text), do: "    " <> text

  defp format_headers(headers), do: headers |> Enum.reduce("", &add_header/2)

  defp add_header({"content-type", _}, acc), do: acc

  defp add_header({key, value}, acc),
    do: apply_tab("#{key}: #{value}\n", 3) <> acc

  defp format_body(body) when is_binary(body),
    do: body |> JSON.decode!() |> format_body()

  defp format_body(body),
    do: body |> JSON.encode!(pretty: true) |> ident_lines(3)
end
