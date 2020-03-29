defmodule Xcribe.ApiBlueprint.Formatter do
  alias Xcribe.Request

  import Xcribe.Helpers.Formatter

  use Xcribe.ApiBlueprint.Templates

  @content_type_opts [default: "text/plain"]

  def metadata_section(api_info) do
    apply_template(
      @metadata_template,
      host: fetch_key(api_info, :host, ""),
      name: fetch_key(api_info, :name, ""),
      description: fetch_key(api_info, :description, "")
    )
  end

  def resource_group(%Request{} = request) do
    apply_template(
      @group_template,
      identifier: prepare_and_upcase(request.resource_group)
    )
  end

  def resource_section(%Request{resource: resource, path: path}) do
    apply_template(
      @resource_template,
      identifier: prepare_and_captalize(resource),
      uri_template: build_uri_template(path, :resource)
    )
  end

  def action_section(%Request{resource: resource, path: path, action: action, verb: verb}) do
    apply_template(
      @action_template,
      identifier_resource: prepare_and_captalize(resource),
      identifier_action: remove_underline(action),
      request_method: String.upcase(verb),
      uri_template: build_uri_template(path, :action)
    )
  end

  def request_section(%Request{description: description, header_params: headers}) do
    apply_template(
      @request_template,
      identifier: purge_string(description),
      media_type: content_type(headers, @content_type_opts)
    )
  end

  def response_section(%Request{status_code: code, resp_headers: headers}) do
    apply_template(@response_template,
      code: to_string(code),
      media_type: content_type(headers, @content_type_opts)
    )
  end

  def request_headers(%Request{header_params: headers}), do: headers_section(headers)

  def response_headers(%Request{resp_headers: headers}), do: headers_section(headers)

  def request_body(%Request{request_body: body, header_params: headers}),
    do: body_section(body, headers)

  def response_body(%Request{status_code: 204}), do: ""

  def response_body(%Request{resp_body: body, resp_headers: headers}),
    do: body_section(body, headers)

  def request_attributes(%Request{request_body: body}, desc \\ %{}),
    do: attributes_section(body, desc)

  def resource_parameters(%Request{path_params: params, path: path}, desc \\ %{}) do
    params
    |> remove_path_ending_arg(path)
    |> parameters_section(desc)
  end

  def action_parameters(%Request{path_params: params, path: path}, desc \\ %{}) do
    resourse_params = params |> remove_path_ending_arg(path) |> Map.keys()

    params
    |> Map.drop(resourse_params)
    |> parameters_section(desc)
  end

  def full_request(%Request{} = struct, desc \\ %{}) do
    Enum.join([
      request_section(struct),
      request_headers(struct),
      request_attributes(struct, desc),
      request_body(struct),
      response_section(struct),
      response_headers(struct),
      response_body(struct)
    ])
  end

  defp parameters_section(params, _desc) when params == %{}, do: ""

  defp parameters_section(params, desc) do
    apply_template(
      @parameters_template,
      parameters_list: format_items_list(params, desc, tab(1), "required, ")
    )
  end

  defp attributes_section(attrs, _desc) when attrs == %{}, do: ""

  defp attributes_section(attrs, desc) do
    apply_template(
      @attributes_template,
      attributes_list: format_items_list(attrs, desc, tab(2))
    )
  end

  defp body_section(body, _headers) when body == "" or body == %{}, do: ""

  defp body_section(body, headers) do
    apply_template(@body_template,
      body: body |> format_body(content_type(headers, @content_type_opts)) |> ident_lines(3)
    )
  end

  defp headers_section(headers) do
    headers
    |> format_headers()
    |> template_for_headers()
  end

  defp template_for_headers(""), do: ""

  defp template_for_headers(headers) do
    apply_template(@headers_template,
      headers: headers
    )
  end

  defp format_items_list(params, desc, tab, type \\ "") do
    Enum.reduce(params, "", fn {key, value}, acc ->
      acc <>
        apply_template(
          @item_template,
          description: get_description(key, desc),
          param: camelize(" #{key}"),
          prefix: tab <> "+",
          type: type <> "#{type_of(value)}",
          value: "#{item_value(value)}"
        )
    end)
  end

  defp item_value(item) when is_list(item) or is_map(item), do: type_of(item)
  defp item_value(item), do: remove_underline(item)

  defp get_description(param, desc),
    do: desc |> fetch_key(param, "The #{param}") |> remove_underline()

  defp remove_path_ending_arg(params, path), do: Map.delete(params, path_ending_arg(path))

  defp format_headers(headers), do: Enum.reduce(headers, "", &add_header/2)

  defp add_header({"content-type", _}, acc), do: acc

  defp add_header({header, value}, acc),
    do: apply_template(@header_item_template, header: header, value: value) <> acc

  defp build_uri_template(path, typ) do
    path
    |> camelize_params()
    |> add_forward_slash()
    |> remove_ending_argument_for(typ)
  end

  defp remove_ending_argument_for(uri, :resource), do: remove_ending_argument(uri)
  defp remove_ending_argument_for(uri, _), do: uri
end
