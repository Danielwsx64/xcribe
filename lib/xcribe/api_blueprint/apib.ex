defmodule Xcribe.ApiBlueprint.APIB do
  @moduledoc false

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

  @tab_size 4

  def encode(%{groups: groups} = struct) do
    metadata(struct) <> groups(groups)
  end

  def metadata(%{host: host, description: desc, name: name}) do
    apply_template(
      @metadata_template,
      host: host,
      name: name,
      description: desc
    )
  end

  def groups(struct) do
    Enum.reduce(struct, "", fn {name, %{resources: resources}}, acc ->
      acc <> group(String.trim(name)) <> reduce_group_resources(resources)
    end)
  end

  def full_resource(uri, %{name: name, parameters: params, actions: actions}) do
    resource(name, uri) <> parameters(params) <> reduce_resource_actions(actions)
  end

  def full_action(uri, %{
        name: name,
        parameters: params,
        query_parameters: query_parameters,
        requests: requests
      }) do
    action(name, action_uri(uri, query_parameters)) <>
      parameters(Map.merge(params, query_parameters)) <> reduce_action_requests(requests)
  end

  def full_request(name, request) do
    request(name, request.content_type) <>
      headers(request.headers) <>
      body(request.body) <>
      schema(request.schema) <> full_response(request.response)
  end

  def full_response(%{status: 204} = response) do
    response(response.status, response.content_type) <> headers(response.headers)
  end

  def full_response(%{} = response) do
    response(response.status, response.content_type) <>
      headers(response.headers) <> body(response.body) <> schema(response.schema)
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

  def schema(schema) when schema == %{}, do: ""

  def schema(schema) do
    apply_template(
      @schema_template,
      schema: schema |> JSON.encode!(pretty: true) |> apply_tab(3)
    )
  end

  def body(body) when body == %{}, do: ""

  def body(body) do
    apply_template(
      @body_template,
      body: body |> JSON.encode!(pretty: true) |> apply_tab(3)
    )
  end

  defp action_uri(uri, query_parameters),
    do: Enum.reduce(query_parameters, uri, &add_query_parameter/2)

  defp add_query_parameter({param, _value}, uri), do: uri <> "{?#{param}}"

  defp reduce_group_resources(resources) do
    Enum.reduce(resources, "", fn {name, res}, acc -> acc <> full_resource(name, res) end)
  end

  defp reduce_resource_actions(actions) do
    Enum.reduce(actions, "", fn {name, act}, acc -> acc <> full_action(name, act) end)
  end

  defp reduce_action_requests(requests) do
    Enum.reduce(requests, "", fn {name, req}, acc -> acc <> full_request(name, req) end)
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
    |> Enum.map(&pad_string(&1, @tab_size * count))
    |> Enum.join("\n")
  end

  defp pad_string("", _number), do: ""
  defp pad_string(string, number), do: String.duplicate(" ", number) <> string
end
