defmodule Xcribe.ApiBlueprint.Formatter do
  @moduledoc false

  alias Plug.Upload
  alias Xcribe.ApiBlueprint.Multipart
  alias Xcribe.APIModel.{Example, Operation, Parameter}
  alias Xcribe.JsonSchema

  import Xcribe.Helpers.Formatter, only: [content_type_boundary: 1, format_path_parameter: 1]

  def put_operation_into_groups(groups, %Operation{} = operation, action_description \\ "") do
    resources = resource_object(operation, action_description)

    Enum.reduce(groups_of(operation), groups, fn group, all ->
      Map.update(all, group, %{resources: resources}, &merge_group(&1, resources))
    end)
  end

  def resource_object(%Operation{} = operation, action_description \\ "") do
    %{
      resource_key(operation) => %{
        name: operation.resource,
        parameters: resource_parameters(operation),
        actions: action_object(operation, action_description)
      }
    }
  end

  def action_object(%Operation{} = operation, action_description \\ "") do
    %{
      action_key(operation) => %{
        name: action_name(operation),
        description: action_description,
        parameters: action_parameters(operation),
        query_parameters: action_query_parameters(operation),
        requests: request_objects(operation.examples)
      }
    }
  end

  def request_objects(examples),
    do: Enum.reduce(examples, %{}, &Map.put(&2, &1.description, request_object(&1)))

  def request_object(%Example{} = example) do
    %{
      content_type: example.request_content_type,
      headers: headers(example.request_headers),
      body: request_body(example),
      schema: request_schema(example),
      response: response_object(example)
    }
  end

  def response_object(%Example{} = example) do
    %{
      status: example.status,
      content_type: example.response_content_type,
      headers: headers(example.response_headers),
      body: response_body(example),
      schema: response_schema(example)
    }
  end

  def action_parameters(%Operation{} = operation),
    do: operation |> path_parameters() |> Enum.reduce(%{}, &put_path_parameter/2)

  def action_query_parameters(%Operation{parameters: parameters}) do
    parameters
    |> Enum.filter(&(&1.location == :query))
    |> Enum.reduce(%{}, &put_query_parameter/2)
  end

  def resource_parameters(%Operation{} = operation) do
    url_params = url_params(operation.path)

    operation
    |> path_parameters()
    |> Enum.filter(&(&1.name in url_params))
    |> Enum.reduce(%{}, &put_path_parameter/2)
  end

  def request_schema(%Example{request_body: body}) when body == %{}, do: %{}

  def request_schema(%Example{} = example) do
    json_schema_for(
      example.request_content_type,
      example.request_body,
      example.request_schema_name
    )
  end

  def response_schema(%Example{} = example) do
    json_schema_for(
      example.response_content_type,
      example.response_body,
      example.response_schema_name
    )
  end

  def response_body(%Example{response_decode_error: nil, response_body: nil}), do: %{}
  def response_body(%Example{response_decode_error: nil} = example), do: example.response_body
  def response_body(%Example{response_decode_error: :missing_content_type}), do: %{}

  def response_body(%Example{} = example), do: example.response_raw_body

  def request_body(%Example{request_body: body}) when body == %{}, do: %{}

  def request_body(%Example{} = example),
    do: body_data_for(example.request_content_type, example.request_headers, example.request_body)

  def action_name(%Operation{action: action, resource: resource}), do: "#{resource} #{action}"

  def action_key(%Operation{path: path, verb: verb}) do
    Enum.reduce(
      url_params(path),
      "#{String.upcase(verb)} #{path}",
      &String.replace(&2, &1, format_path_parameter(&1))
    )
  end

  def resource_key(%Operation{path: path}) do
    Enum.reduce(
      url_params(path),
      resource_path(path),
      &String.replace(&2, &1, format_path_parameter(&1))
    )
  end

  defp merge_group(group, resources),
    do: %{group | resources: merge_resources(group.resources, resources)}

  defp merge_resources(base, new) do
    Enum.reduce(new, base, fn {key, resource}, all ->
      Map.update(all, key, resource, &merge_resource(&1, resource))
    end)
  end

  defp merge_resource(base, new), do: %{base | actions: Map.merge(base.actions, new.actions)}

  defp path_parameters(%Operation{parameters: parameters}),
    do: Enum.filter(parameters, &(&1.location == :path))

  defp put_path_parameter(%Parameter{} = parameter, parameters),
    do: Map.put(parameters, format_path_parameter(parameter.name), schema_for(parameter, true))

  defp put_query_parameter(%Parameter{} = parameter, parameters),
    do: Map.put(parameters, parameter.name, schema_for(parameter, false))

  defp resource_path(path) do
    ~r/(.*)(?=\/{.*}$)|(.*)/
    |> Regex.run(path, capture: :all_but_first)
    |> List.last()
  end

  defp groups_of(%Operation{tags: []}), do: [""]
  defp groups_of(%Operation{tags: tags}), do: tags

  defp json_schema_for("application/json", body, name) when is_map(body) or is_list(body),
    do: JsonSchema.schema_for({name, body})

  defp json_schema_for(_content_type, _body, _name), do: %{}

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

  defp schema_for(%Parameter{examples: examples}, required) do
    {nil, List.first(examples)}
    |> JsonSchema.schema_for()
    |> add_required(required)
  end

  defp headers(headers), do: headers |> Enum.into(%{}) |> Map.delete("content-type")

  defp add_required(map, true), do: Map.put(map, :required, true)
  defp add_required(map, false), do: map

  defp url_params(path) do
    case Regex.run(~r/\{(.*?)\}.+/, path, capture: :all_but_first) do
      nil -> []
      result -> result
    end
  end
end
