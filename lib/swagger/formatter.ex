defmodule Xcribe.Swagger.Formatter do
  @moduledoc """
  Creates Swagger maps according to OpenAPI Specification
  """
  alias Xcribe.{JSON, Request}

  import Xcribe.Swagger.Descriptor,
    only: [get_param_description: 3, get_content_type: 1, get_attr_description: 2]

  def request_parameters(%Request{} = request) do
    []
    |> include_params(request.path_params, request, "path")
    |> include_params(request.query_params, request, "query")
    |> include_params(request.header_params, request, "header")
  end

  def request_body(%{request_body: body} = request) do
    %{
      "required" => true,
      "content" => %{
        get_content_type(request) => %{
          "schema" => %{
            "type" => "object",
            "properties" => params_schema_object(body, request)
          }
        }
      }
    }
  end

  def format_responses(request) do
    %{
      request.status_code => %{
        "description" => request.description,
        "headers" => format_headers(request.resp_headers),
        "content" => format_response_body(request)
      }
    }
  end

  defp include_params(list, params, request, inn) do
    Enum.reduce(params, list, fn {name, value}, acc ->
      [build_parameter_object(name, value, request, inn) | acc]
    end)
  end

  defp build_parameter_object(name, value, %{action: action, controller: controller}, inn) do
    %{
      "name" => name,
      "in" => inn,
      "description" => get_param_description(name, controller, action),
      "required" => inn == "path",
      "schema" => %{"type" => type_of(value)}
    }
  end

  defp params_schema_object(params, %{controller: controller}) do
    Enum.reduce(params, %{}, fn {key, value}, map ->
      Map.put(map, key, build_simple_schema(key, value, controller))
    end)
  end

  defp build_simple_schema(name, value, controller) do
    %{"type" => type_of(value), "description" => get_attr_description(name, controller)}
  end

  defp format_headers(headers) do
    Enum.reduce(headers, %{}, fn {k, v}, acc ->
      Map.put(acc, k, %{"schema" => %{"type" => type_of(v)}})
    end)
  end

  defp format_response_body(%{resp_body: body} = request) do
    %{get_content_type(request) => %{"schema" => format_body_schema(body)}}
  end

  defp format_body_schema(body) do
    body
    |> JSON.decode()
    |> case do
      {:ok, map} -> map
      {:error, %{data: data}} -> data
    end
    |> body_schema()
  end

  defp body_schema(body) when is_bitstring(body) do
    %{"type" => "string", "example" => body}
  end

  defp body_schema(body) when is_map(body) do
    %{"type" => "object", "properties" => params_schema_object(body, %{controller: nil})}
  end

  defp body_schema([body | _t]) do
    %{"type" => "array", "items" => body_schema(body)}
  end

  defp type_of(value) when is_integer(value), do: "integer"
  defp type_of(_), do: "string"
end
