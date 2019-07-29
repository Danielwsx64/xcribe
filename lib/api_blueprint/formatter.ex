defmodule Xcribe.ApiBlueprint.Formatter do
  alias Xcribe.JSON

  def resource_group(%{resource_group: name}),
    do: ("## Group " <> String.upcase("#{name}\n")) |> remove_underline()

  def resource(%{resource: resource, path: path}) do
    resource_name = resource |> remove_underline() |> capitalize()
    resource_path = build_path(path, last_argument: false)

    "## #{resource_name} #{resource_path}\n"
  end

  def resource_parameters(struct, descriptions \\ %{})
  def resource_parameters(%{path_params: params}, _desc) when params == %{}, do: ""

  def resource_parameters(%{path_params: params, path: path}, desc) do
    params
    |> resource_path_parameters(path)
    |> format_parameters(desc)
  end

  def action_parameters(struct, descriptions \\ %{})
  def action_parameters(%{path_params: params}, _desc) when params == %{}, do: ""

  def action_parameters(%{path_params: params, path: path}, desc) do
    resourse_params = params |> resource_path_parameters(path) |> Map.keys()

    params
    |> Map.drop(resourse_params)
    |> format_parameters(desc)
  end

  def resource_action(%{resource: resource, path: path, action: action, verb: verb}) do
    resource_name = resource |> remove_underline() |> capitalize()
    resource_path = build_path(path, verb: verb, last_argument: true)
    resource_action = action |> remove_underline()

    "### #{resource_name} #{resource_action} #{resource_path}\n"
  end

  def overview(api_info) do
    """
    FORMAT: 1A
    HOST: #{fetch_key(api_info, :host, "")}

    # #{fetch_key(api_info, :name, "")}
    #{fetch_key(api_info, :description, "")}

    """
  end

  def full_request(struct, desc \\ %{}) do
    [
      request_description(struct),
      request_headers(struct),
      request_attributes(struct, desc),
      response_description(struct),
      response_headers(struct),
      response_body(struct)
    ]
    |> Enum.join()
  end

  def request_description(%{description: description, header_params: headers}),
    do: "+ Request #{clean_description(description)} (#{find_content_type(headers)})\n"

  def request_headers(%{header_params: []}), do: ""
  def request_headers(%{header_params: headers}), do: headers_section(headers)

  def response_headers(%{resp_headers: []}), do: ""
  def response_headers(%{resp_headers: headers}), do: headers_section(headers)

  def request_body(%{request_body: body}) when body == %{}, do: ""
  def request_body(%{request_body: body}), do: body_section(body)

  def request_attributes(structs, descriptions \\ %{})
  def request_attributes(%{request_body: body}, _desc) when body == %{}, do: ""
  def request_attributes(%{request_body: body}, desc), do: attributes_section(body, desc)

  def response_body(%{resp_body: body}) when body == %{}, do: ""
  def response_body(%{resp_body: body}), do: body_section(body)

  def response_description(%{status_code: code, resp_headers: headers}),
    do: "+ Response #{code} (#{find_content_type(headers)})\n"

  defp resource_path_parameters(params, path) do
    ending_arg =
      case Regex.run(~r/{(\w*)}$/, path) do
        [_, arg] -> arg
        _ -> nil
      end

    params
    |> Map.delete(ending_arg)
  end

  defp format_parameters(params, _desc) when params == %{}, do: ""

  defp format_parameters(params, desc) do
    params_list =
      params
      |> define_schema(desc)
      |> ident_lines(1)

    "+ Parameters\n\n" <> params_list <> "\n"
  end

  defp remove_underline(text), do: String.replace(text, "_", " ")

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

    if headers == "", do: "", else: title <> headers <> "\n"
  end

  def body_section(body) do
    title = "+ Body\n\n" |> apply_tab(1)
    body = format_body(body)

    title <> body <> "\n"
  end

  def attributes_section(attrs, desc) do
    title = "+ Attributes\n\n" |> apply_tab(1)

    body =
      attrs
      |> define_schema(desc, camelize: false, required: false, prefix: "+ ")
      |> ident_lines(2)

    title <> body <> "\n"
  end

  defp define_schema(params, desc, opts \\ []) do
    opts = Keyword.merge([camelize: true, required: true, prefix: ""], opts)
    camelize = Keyword.fetch!(opts, :camelize)
    required = Keyword.fetch!(opts, :required)
    prefix = Keyword.fetch!(opts, :prefix)

    Enum.reduce(params, "", fn {key, value}, acc ->
      param = if camelize, do: Macro.camelize("+ " <> key), else: key
      type = if required, do: "required, #{type_of(value)}", else: "#{type_of(value)}"
      description = fetch_key(desc, key, "The #{key}")

      acc <> "#{prefix}#{param}: `#{value}` (#{type}) - #{description}\n"
    end)
  end

  defp type_of(item) when is_number(item), do: "number"
  defp type_of(item) when is_binary(item), do: "string"
  defp type_of(item) when is_boolean(item), do: "boolean"

  defp capitalize(string) do
    string
    |> String.split()
    |> Enum.map(&String.capitalize/1)
    |> Enum.join(" ")
  end

  defp build_path(path, opts) do
    options = Keyword.merge([verb: nil, last_argument: true], opts)

    verb = Keyword.fetch!(options, :verb)
    last_argument = Keyword.fetch!(options, :last_argument)

    path
    |> add_forward_slash()
    |> remove_ending_argument(!last_argument)
    |> camelize_params()
    |> into_brackets(verb)
  end

  defp add_forward_slash(path),
    do: if(Regex.match?(~r/\/$/, path), do: path, else: "#{path}/")

  defp into_brackets(path, nil), do: "[#{path}]"
  defp into_brackets(path, verb), do: "[#{String.upcase(verb)} #{path}]"

  defp remove_ending_argument(path, false), do: path

  defp remove_ending_argument(path, true) do
    case Regex.run(~r/({\w*}\/$)/, path) do
      nil -> path
      [capture | _] -> String.replace(path, capture, "")
    end
  end

  defp camelize_params(path) do
    ~r/({\w*})/
    |> Regex.run(path)
    |> case do
      nil -> []
      p -> Enum.uniq(p)
    end
    |> Enum.reduce(path, fn param, text -> String.replace(text, param, Macro.camelize(param)) end)
  end

  defp clean_description(description) do
    description |> String.replace(~r/\W/, " ") |> String.replace(~r/\s+/, " ")
  end

  defp ident_lines(text, count) do
    text
    |> String.split("\n")
    |> Enum.map(fn l -> if(l == "", do: "", else: apply_tab(l, count)) end)
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

  defp fetch_key(map, key, default) do
    case Map.fetch(map, key) do
      {:ok, value} -> value
      _ -> default
    end
  end
end
