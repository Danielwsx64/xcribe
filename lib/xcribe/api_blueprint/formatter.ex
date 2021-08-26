defmodule Xcribe.ApiBlueprint.Formatter do
  @moduledoc false

  alias Plug.Upload
  alias Xcribe.ApiBlueprint.Multipart
  alias Xcribe.{ContentDecoder, JsonSchema, Request}

  import Xcribe.Helpers.Formatter

  def put_object_into_groups(requests_map, request) do
    Enum.reduce(request.groups, requests_map, fn group, requests ->
      Map.update(
        requests,
        group,
        request,
        &merge_group(&1, request)
      )
    end)
  end

  def full_request_object(%Request{} = request) do
    %{
      summary: "",
      description: "",
      groups: request.groups_tags,
      resources: resource_object(request)
    }
  end

  def resource_object(%Request{resource: resource} = request) do
    %{
      resource_key(request) => %{
        name: resource,
        summary: "",
        description: "",
        parameters: resource_parameters(request),
        actions: action_object(request)
      }
    }
  end

  def action_object(%Request{} = request) do
    %{
      action_key(request) => %{
        name: action_name(request),
        summary: "",
        description: "",
        parameters: action_parameters(request),
        query_parameters: action_query_parameters(request),
        requests: request_object(request)
      }
    }
  end

  def request_object(%Request{description: desc, header_params: headers} = request) do
    %{
      desc => %{
        content_type: content_type(headers),
        headers: headers(headers),
        body: request_body(request),
        schema: request_schema(request),
        response: response_object(request)
      }
    }
  end

  def response_object(%Request{resp_headers: headers, status_code: code} = request) do
    %{
      status: code,
      content_type: content_type(headers),
      headers: headers(headers),
      body: response_body(request),
      schema: response_schema(request)
    }
  end

  def action_parameters(%Request{path_params: path_params}) do
    Enum.reduce(path_params, %{}, &reduce_path_params/2)
  end

  def action_query_parameters(%Request{query_params: query_params}) do
    Enum.reduce(query_params, %{}, &reduce_query_params/2)
  end

  def resource_parameters(%Request{path: path, path_params: path_params}) do
    path_params
    |> Map.take(url_params(path))
    |> Enum.reduce(%{}, &reduce_path_params/2)
  end

  def response_schema(%Request{__meta__: meta, resp_body: body, resp_headers: headers}) do
    content_type = content_type(headers)

    json_schema_for(content_type, response_content(body, content_type, meta))
  end

  def response_body(%Request{__meta__: %{config: config}, resp_body: body, resp_headers: headers}) do
    case content_type(headers) do
      nil -> %{}
      content_type -> ContentDecoder.decode!(body, content_type, config)
    end
  end

  def request_schema(%Request{request_body: body}) when body == %{}, do: %{}

  def request_schema(%Request{request_body: body, header_params: headers}) do
    headers
    |> content_type()
    |> json_schema_for(body)
  end

  def request_body(%Request{request_body: body}) when body == %{}, do: %{}

  def request_body(%Request{request_body: body, header_params: headers}) do
    headers
    |> content_type()
    |> body_data_for(headers, body)
  end

  def action_name(%Request{action: action, resource: resource}) do
    "#{resource} #{action}"
  end

  def action_key(%Request{path: path, verb: verb}) do
    Enum.reduce(
      url_params(path),
      "#{String.upcase(verb)} #{path}",
      &String.replace(&2, &1, format_path_parameter(&1))
    )
  end

  def resource_key(%Request{path: path}) do
    Enum.reduce(
      url_params(path),
      resource_path(path),
      &String.replace(&2, &1, format_path_parameter(&1))
    )
  end

  defp merge_group(group, new_request) do
    %{group | resources: merge_group_resources(group.resources, new_request.resources)}
  end

  defp merge_group_resources(resources, new_request) do
    resource_key = object_key(new_request)

    Map.update(
      resources,
      resource_key,
      new_request[resource_key],
      &merge_resource(&1, new_request[resource_key])
    )
  end

  defp merge_resource(resource, new_request) do
    %{resource | actions: merge_resource_actions(resource.actions, new_request.actions)}
  end

  defp merge_resource_actions(actions, new_request) do
    action_key = object_key(new_request)

    Map.update(
      actions,
      action_key,
      new_request[action_key],
      &merge_action(&1, new_request[action_key])
    )
  end

  defp merge_action(action, new_request) do
    %{
      action
      | requests: Map.merge(action.requests, new_request.requests),
        query_parameters: Map.merge(action.query_parameters, new_request.query_parameters)
    }
  end

  defp object_key(%{} = request) do
    request
    |> Map.keys()
    |> List.first()
  end

  defp resource_path(path) do
    ~r/(.*)(?=\/{.*}$)|(.*)/
    |> Regex.run(path, capture: :all_but_first)
    |> List.last()
  end

  defp json_schema_for("application/json", body) when is_map(body) or is_list(body),
    do: JsonSchema.schema_for(body)

  defp json_schema_for(_content_type, _body), do: %{}

  defp body_data_for("multipart/form-data", headers, body) when is_map(body) do
    %Multipart{
      parts: Enum.reduce(body, [], &data_schema/2),
      boundary: content_type_boundary(headers)
    }
  end

  defp body_data_for(_content_type, _headers, body), do: body

  defp data_schema({key, %Upload{} = upload}, acc) do
    [
      %{
        content_type: upload.content_type,
        name: key,
        value: "image-binary",
        filename: upload.filename
      }
      | acc
    ]
  end

  defp data_schema({key, value}, acc),
    do: [%{content_type: "text/plain", name: key, value: value} | acc]

  defp reduce_path_params({param, value}, parameters) do
    Map.put(
      parameters,
      format_path_parameter(param),
      schema_for(value, true)
    )
  end

  defp reduce_query_params({param, value}, parameters) do
    Map.put(
      parameters,
      param,
      schema_for(value, false)
    )
  end

  defp schema_for(value, required) do
    {nil, value}
    |> JsonSchema.schema_for()
    |> add_required(required)
  end

  defp headers(headers), do: headers |> Enum.into(%{}) |> Map.delete("content-type")

  defp add_required(map, true), do: Map.put(map, :required, true)
  defp add_required(map, false), do: map

  defp response_content(body, "application/json", %{config: config}) when is_binary(body),
    do: ContentDecoder.decode!(body, "application/json", config)

  defp response_content(body, _content_type, _meta), do: body

  defp url_params(path) do
    case Regex.run(~r/\{(.*?)\}.+/, path, capture: :all_but_first) do
      nil -> []
      result -> result
    end
  end
end
