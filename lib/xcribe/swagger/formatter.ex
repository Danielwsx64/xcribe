defmodule Xcribe.Swagger.Formatter do
  @moduledoc false

  alias Xcribe.ContentDecoder
  alias Xcribe.JsonSchema
  alias Xcribe.Request

  import Xcribe.Helpers.Formatter, only: [content_type: 1, authorization: 1]

  def openapi_object(specifications) do
    %{
      openapi: "3.0.3",
      info: %{
        title: specifications.name,
        description: specifications.description,
        version: specifications.version
      },
      servers: specifications.servers,
      paths: nil,
      components: nil
    }
  end

  def request_objects(%Request{path: path, verb: verb} = request, config) do
    {request_is_array, request_schema} = request |> request_schema() |> pop_from_array()
    {response_is_array, response_schema} = request |> response_schema(config) |> pop_from_array()

    security = security_scheme_object(request)

    object = %{
      description: request.description,
      responses: responses_object(request, response_schema, response_is_array),
      parameters: parameter_objects_from_request(request),
      security: security_list(security),
      tags: request.groups_tags
    }

    path = %{
      path => %{
        verb => add_request_body_if_needed(object, request, request_schema, request_is_array)
      }
    }

    %{path: path, schemas: Map.merge(request_schema, response_schema), security: security}
  end

  defp add_request_body_if_needed(obj, _request, schema, _array) when schema == %{}, do: obj

  defp add_request_body_if_needed(obj, request, schema, is_array) do
    Map.put(obj, :requestBody, request_body_object(request, schema, is_array))
  end

  defp request_body_object(%{header_params: headers}, schema, is_array) do
    %{
      content: %{content_type(headers) => %{schema: buil_schema_obj(schema, is_array)}}
    }
  end

  defp responses_object(%Request{resp_headers: headers, status_code: status}, schema, is_array) do
    object = %{headers: Enum.reduce(headers, %{}, &reduce_header_objects/2), description: ""}

    if schema == %{} do
      %{status => object}
    else
      %{
        status =>
          Map.put(object, :content, %{
            content_type(headers) => %{schema: buil_schema_obj(schema, is_array)}
          })
      }
    end
  end

  defp buil_schema_obj(schema, is_array) do
    ref = %{"$ref" => "#/components/schemas/#{schema_name(schema)}"}

    if is_array, do: %{type: "array", items: ref}, else: ref
  end

  defp security_list(security) when security == %{}, do: []

  defp security_list(security) do
    security
    |> Map.keys()
    |> Enum.map(&%{&1 => []})
  end

  defp request_schema(%{request_body: body}) when body == %{}, do: %{}

  defp request_schema(%{request_body: %{} = body} = request) do
    %{
      Request.format_req_schema(request) =>
        JsonSchema.schema_for(body, title: false, example: true)
    }
  end

  defp response_schema(%{resp_body: ""}, _config), do: %{}

  defp response_schema(%Request{resp_body: body, resp_headers: headers} = request, config) do
    case response_content(body, content_type(headers), config) do
      content when content == %{} ->
        %{}

      content ->
        %{
          Request.format_schema(request) =>
            JsonSchema.schema_for(content, title: false, example: true)
        }
    end
  end

  defp pop_from_array(schema) when schema == %{}, do: {false, %{}}

  defp pop_from_array(schema) do
    name = schema_name(schema)

    case Map.fetch!(schema, name) do
      %{type: "array", items: schema} -> {true, %{name => schema}}
      %{type: "object"} -> {false, schema}
    end
  end

  defp schema_name(%{} = schema), do: schema |> Map.keys() |> List.first()

  defp response_content(body, "application/json", config) when is_binary(body) do
    ContentDecoder.decode!(body, "application/json", config)
  end

  defp response_content(_body, _content_type, _config), do: %{}

  defp security_scheme_object(%Request{header_params: headers}) do
    case authorization(headers) do
      nil -> %{}
      auth -> auth |> security_type() |> security_scheme_by_type()
    end
  end

  defp parameter_objects_from_request(%Request{} = request) do
    path_list(request) ++ header_list(request) ++ query_list(request)
  end

  defp reduce_header_objects({"content-type", _value}, headers), do: headers

  defp reduce_header_objects({title, value}, headers) do
    Map.put(
      headers,
      title,
      %{schema: JsonSchema.schema_for({title, value}, title: false)}
    )
  end

  defp header_list(%{header_params: params}) do
    Enum.reduce(params, [], &reduce_header_parameter/2)
  end

  defp path_list(%{path_params: params}), do: Enum.map(params, &parameter_object(&1, "path"))
  defp query_list(%{query_params: params}), do: Enum.map(params, &parameter_object(&1, "query"))

  defp reduce_header_parameter({"content-type", _value}, acc), do: acc
  defp reduce_header_parameter({"authorization", _value}, acc), do: acc
  defp reduce_header_parameter({"accept", _value}, acc), do: acc
  defp reduce_header_parameter(param, acc), do: [parameter_object(param, "header") | acc]

  defp parameter_object({name, value}, inn) do
    parameter_object_add_required(%{
      name: name,
      in: inn,
      schema: JsonSchema.schema_for({name, value}, title: false),
      example: value
    })
  end

  defp parameter_object_add_required(%{in: "path"} = param), do: Map.put(param, :required, true)
  defp parameter_object_add_required(param), do: param

  defp security_type("Bearer" <> _tail), do: "bearer"
  defp security_type("Basic" <> _tail), do: "basic"
  defp security_type(_), do: "api_key"

  defp security_scheme_by_type("api_key") do
    %{
      "api_key" => %{
        "type" => "apiKey",
        "name" => "authorization",
        "in" => "header"
      }
    }
  end

  defp security_scheme_by_type("bearer") do
    %{
      "bearer" => %{
        type: "http",
        scheme: "bearer",
        bearerFormat: "JWT"
      }
    }
  end

  defp security_scheme_by_type("basic") do
    %{
      "basic" => %{
        type: "http",
        scheme: "basic"
      }
    }
  end
end
