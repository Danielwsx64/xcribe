defmodule Xcribe.Swagger.Formatter do
  @moduledoc ~S"""
  Format a given `Xcribe.Request` according to OpenAPI Specification.

  To know more about the specifications [OpenAPI 3.0.3](https://github.com/OAI/OpenAPI-Specification/blob/master/versions/3.0.3.md)
  """

  alias Xcribe.{JSON, Request}
  alias Xcribe.Swagger.Types

  import Xcribe.Helpers.Formatter, only: [content_type: 1, authorization: 1]

  @doc """
  Return an empty struct of an OpenAPI Object.
  """
  def raw_openapi_object do
    %{
      openapi: "3.0.3",
      info: nil,
      servers: nil,
      paths: nil,
      components: nil
    }
  end

  @doc """
  Return an Info Object builded from the api_info suplied by the `Xcribe.Information`.
  """
  def info_object(api_info) do
    %{title: api_info.name, description: api_info.description, version: "1"}
  end

  @doc """
  Return a Server Object builded from the api_info suplied by the `Xcribe.Information`.
  """
  def server_object(api_info) do
    [%{url: api_info.host, description: ""}]
  end

  @doc """
  Return a Path Item Object from the given request.
  """
  def path_item_object_from_request(%Request{verb: verb} = request) do
    %{
      verb =>
        path_item_object_add_request_body(
          request,
          %{
            description: "",
            summary: "",
            responses: responses_object_from_request(request),
            parameters: parameter_objects_from_request(request),
            security: security_requirement_object_by_request(request)
          }
        )
    }
  end

  @doc """
  Return a Request Body Object from given request
  """
  def request_body_object_from_request(%Request{header_params: headers, request_body: body}) do
    media_type_object(headers, body)
  end

  @doc """
  Return a Response Object from given request
  """
  def response_object_from_request(%Request{resp_headers: headers, resp_body: body}) do
    headers
    |> media_type_object(body)
    |> response_object_add_headers(headers)
  end

  @doc """
  Return a list of Parameter Objects from a given request.
  """
  def parameter_objects_from_request(%Request{} = request) do
    path_list(request) ++ header_list(request) ++ query_list(request)
  end

  @doc """
  Return the security requirement for given request.
  """
  def security_requirement_object_by_request(%Request{header_params: headers}) do
    case authorization(headers) do
      nil -> []
      auth -> [%{security_type(auth) => []}]
    end
  end

  @doc """
  Return the Security Scheme Object for given request.
  """
  def security_scheme_object_from_request(%Request{header_params: headers}) do
    case authorization(headers) do
      nil -> %{}
      auth -> auth |> security_type() |> security_scheme_by_type()
    end
  end

  @opt_no_title {:title, false}
  @opt_example {:example, true}

  @doc ~S"""
  Return an schema object for given attribute/parameter.

  ### Options:
    * `:title` - Include the schema title, default is `true`.
    * `:example` - Include the schema example, default is `false`.
  """
  def schema_object_for(param, opts \\ [])

  def schema_object_for({title, value}, opts) when is_map(value) do
    %{type: "object"}
    |> schema_add_title(title, @opt_no_title in opts)
    |> schema_add_properties(value)
  end

  def schema_object_for({title, value}, opts) when is_list(value) do
    %{type: "array"}
    |> schema_add_title(title, @opt_no_title in opts)
    |> schema_add_items(value)
  end

  def schema_object_for({title, value}, opts) do
    %{type: Types.type_for(value)}
    |> schema_add_title(title, @opt_no_title in opts)
    |> schema_add_format(Types.format_for(value))
    |> schema_add_example(value, @opt_example in opts)
  end

  defp path_item_object_add_request_body(%{request_body: body}, path_item_object)
       when body == %{},
       do: path_item_object

  defp path_item_object_add_request_body(request, path_item_object) do
    Map.put(
      path_item_object,
      :requestBody,
      request_body_object_from_request(request)
    )
  end

  defp responses_object_from_request(%Request{status_code: status} = request) do
    %{status => response_object_from_request(request)}
  end

  defp media_type_object(_headers, ""), do: %{description: ""}

  defp media_type_object(headers, content) do
    media_type = content_type(headers)

    %{
      description: "",
      content: %{
        media_type => %{schema: build_schema_for_media(content, media_type)}
      }
    }
  end

  defp build_schema_for_media(content, "application/json") when is_binary(content) do
    schema_object_for({:build_schema_for_media, JSON.decode!(content)}, title: false)
  end

  defp build_schema_for_media(content, _) when is_map(content) do
    schema_object_for({:build_schema_for_media, content}, title: false)
  end

  defp response_object_add_headers(response_object, headers) do
    Map.put(
      response_object,
      :headers,
      Enum.reduce(headers, %{}, &reduce_header_objects/2)
    )
  end

  defp reduce_header_objects({"content-type", _value}, headers), do: headers

  defp reduce_header_objects({title, value}, headers) do
    Map.put(
      headers,
      title,
      %{
        description: "",
        schema: schema_object_for({title, value}, title: false)
      }
    )
  end

  defp header_list(%{header_params: params}),
    do: Enum.reduce(params, [], &reduce_header_parameter/2)

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
      schema: schema_object_for({:parameter_object, value}, title: false),
      example: value
    })
  end

  defp parameter_object_add_required(%{in: "path"} = param), do: Map.put(param, :required, true)
  defp parameter_object_add_required(param), do: param

  defp schema_add_title(schema, _title, true), do: schema
  defp schema_add_title(schema, title, false), do: Map.put(schema, :title, title)

  defp schema_add_format(schema, ""), do: schema
  defp schema_add_format(schema, format), do: Map.put(schema, :format, format)

  defp schema_add_example(schema, value, true), do: Map.put(schema, :example, value)
  defp schema_add_example(schema, _value, false), do: schema

  defp schema_add_items(schema, []) do
    Map.put(schema, :items, %{type: "string"})
  end

  defp schema_add_items(schema, value) do
    Map.put(
      schema,
      :items,
      schema_object_for({:schema_add_items, List.first(value)}, title: false)
    )
  end

  defp schema_add_properties(schema, value) do
    Map.put(schema, :properties, reduce_properties(value))
  end

  defp reduce_properties(value), do: Enum.reduce(value, %{}, &reduce_properties_func/2)

  defp reduce_properties_func({title, value}, properties) do
    Map.put(properties, title, schema_object_for({:reduce_properties_func, value}, title: false))
  end

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
