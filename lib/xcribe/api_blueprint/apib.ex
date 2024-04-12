defmodule Xcribe.ApiBlueprint.APIB do
  @moduledoc false

  alias Xcribe.ApiBlueprint.Multipart
  alias Xcribe.JSON

  @metadata_template "FORMAT: 1A\nHOST: --host--\n\n# --name--\n--description--\n\n"
  @group_template "## Group --identifier--\n"
  @resource_template "## --identifier-- [--uri--]\n"
  @parameters_template "+ Parameters\n\n--parameters--\n"
  @item_template "    + --name--: `--value--` (--type--)\n"
  @action_template "### --identifier-- [--uri--]\n"
  @headers_template "    + Headers\n\n--headers--\n"
  @header_item_template "            --header--: --value--\n"
  @request_template "+ Request --identifier-- (--media_type--)\n"
  @response_template "+ Response --code-- (--media_type--)\n"
  @schema_template "    + Schema\n\n--schema--\n\n"
  @body_template "    + Body\n\n--body--\n\n"

  @multipart_template "\n\n--boundary--\nContent-Disposition: form-data; name=\"--name--\"\nContent-Type: --content_type--\n\n--value--"

  @tab_size 4

  def encode(%{groups: groups} = struct, config) do
    metadata(struct) <> groups(groups, config)
  end

  def metadata(%{host: host, description: desc, name: name}) do
    apply_template(
      @metadata_template,
      host: host,
      name: name,
      description: desc
    )
  end

  def groups(struct, config) do
    Enum.reduce(struct, "", fn {name, %{resources: resources}}, acc ->
      acc <> group(String.trim(name)) <> reduce_group_resources(resources, config)
    end)
  end

  def full_resource(uri, %{name: name, parameters: params, actions: actions}, config) do
    resource(name, uri) <> parameters(params) <> reduce_resource_actions(actions, config)
  end

  def full_action(
        uri,
        %{
          name: name,
          parameters: params,
          query_parameters: query_parameters,
          requests: requests
        },
        config
      ) do
    action(name, action_uri(uri, query_parameters)) <>
      parameters(Map.merge(params, query_parameters)) <> reduce_action_requests(requests, config)
  end

  def full_request(name, request, config) do
    request(name, request.content_type) <>
      headers(request.headers) <>
      body(request.body, config) <>
      schema(request.schema, config) <> full_response(request.response, config)
  end

  def full_response(%{status: 204} = response, _config) do
    response(response.status, response.content_type) <> headers(response.headers)
  end

  def full_response(%{} = response, config) do
    response(response.status, response.content_type) <>
      headers(response.headers) <> body(response.body, config) <> schema(response.schema, config)
  end

  def group(""), do: ""
  def group(name), do: apply_template(@group_template, identifier: name)

  def resource(name, uri), do: apply_template(@resource_template, identifier: name, uri: uri)
  def action(name, uri), do: apply_template(@action_template, identifier: name, uri: uri)

  def headers(headers) when headers == %{}, do: ""

  def headers(headers),
    do: apply_template(@headers_template, headers: reduce_header_items(headers))

  def parameters(parameters) when parameters == %{}, do: ""

  def parameters(parameters),
    do: apply_template(@parameters_template, parameters: reduce_parameters_items(parameters))

  def request(name, media_type) do
    apply_template(@request_template, identifier: name, media_type: media_type || "text/plain")
  end

  def response(code, media_type),
    do:
      apply_template(@response_template,
        code: to_string(code),
        media_type: media_type || "text/plain"
      )

  def schema(schema, _config) when schema == %{}, do: ""

  def schema(schema, config) do
    apply_template(
      @schema_template,
      schema: schema |> JSON.encode!([pretty: true], config) |> apply_tab(3)
    )
  end

  def body(%Multipart{} = multipart, _config) do
    apply_template(
      @body_template,
      body: build_multipart_body(multipart)
    )
  end

  def body(body, _config) when body == %{}, do: ""

  def body(body, config) do
    apply_template(
      @body_template,
      body: body |> JSON.encode!([pretty: true], config) |> apply_tab(3)
    )
  end

  defp build_multipart_body(multipart),
    do: Enum.reduce(multipart.parts, "", &build_multipart_template(&1, &2, multipart.boundary))

  defp build_multipart_template(part, acc, boundary) do
    part_template =
      apply_template(
        @multipart_template,
        boundary: boundary,
        name: part.name,
        content_type: part.content_type,
        value: part.value
      )

    acc <> apply_tab(part_template, 3)
  end

  defp action_uri(uri, query_parameters),
    do: Enum.reduce(query_parameters, uri, &add_query_parameter/2)

  defp add_query_parameter({param, _value}, uri), do: uri <> "{?#{param}}"

  defp reduce_group_resources(resources, config) do
    Enum.reduce(resources, "", fn {name, res}, acc -> acc <> full_resource(name, res, config) end)
  end

  defp reduce_resource_actions(actions, config) do
    Enum.reduce(actions, "", fn {name, act}, acc -> acc <> full_action(name, act, config) end)
  end

  defp reduce_action_requests(requests, config) do
    Enum.reduce(requests, "", fn {name, req}, acc -> acc <> full_request(name, req, config) end)
  end

  defp reduce_parameters_items(parameters),
    do: Enum.reduce(parameters, "", &parameter_item/2)

  defp parameter_item({name, %{items: items, type: "array"}}, acc) do
    acc <>
      apply_template(@item_template,
        name: name,
        value: items[:example],
        type: "array(#{items[:type]})"
      )
  end

  defp parameter_item({name, %{example: ex, type: type}}, acc),
    do: acc <> apply_template(@item_template, name: name, value: ex, type: type)

  defp reduce_header_items(headers), do: Enum.reduce(headers, "", &header_item/2)

  defp header_item({header, value}, acc),
    do: acc <> "#{apply_template(@header_item_template, header: header, value: value)}"

  defp apply_template(template, keyword),
    do: Enum.reduce(keyword, template, &reduce_keys/2)

  defp reduce_keys({key, value}, template),
    do: String.replace(template, "--#{key}--", value)

  defp apply_tab(text, count) do
    text
    |> String.split("\n")
    |> Enum.map_join("\n", &pad_string(&1, @tab_size * count))
  end

  defp pad_string("", _number), do: ""
  defp pad_string(string, number), do: String.duplicate(" ", number) <> string
end
