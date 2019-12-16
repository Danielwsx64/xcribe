defmodule Xcribe.Swagger do
  @moduledoc """
  Treats list of Requests and generates OpenAPI 3.0 JSON
  """
  alias Xcribe.Config
  alias Xcribe.Swagger.{Descriptor, Formatter}

  def generate_doc(requests) do
    swagger_json()
    |> add_requests(requests)
    |> add_security(requests)
    |> Xcribe.JSON.encode!()
  end

  defp swagger_json() do
    %{
      "openapi" => "3.0.0",
      "info" => %{
        "title" => Map.get(xcribe_info(), :name, ""),
        "version" => Map.get(xcribe_info(), :version, "0.1.0"),
        "description" => Map.get(xcribe_info(), :description, "")
      }
    }
  end

  defp add_requests(swagger_map, requests) do
    paths =
      requests
      |> Enum.sort_by(& &1.status_code)
      |> Enum.reduce(%{}, fn x, acc ->
        Map.put(acc, x.path, Map.merge(acc[x.path] || %{}, handle_request(x, acc)))
      end)

    Map.put(swagger_map, "paths", paths)
  end

  defp add_security(swagger_map, requests) do
    requests
    |> Enum.any?(&has_authorization_header?/1)
    |> if do
      Map.put(swagger_map, "components", %{
        "securitySchemes" => %{
          "api_key" => %{"name" => "api_key", "type" => "apiKey", "in" => "header"}
        }
      })
    else
      swagger_map
    end
  end

  defp has_authorization_header?(request) do
    request
    |> Map.fetch!(:header_params)
    |> Enum.any?(fn {header, _} -> String.downcase(header) == "authorization" end)
  end

  defp handle_request(request, swagger_paths) do
    swagger_paths
    |> Map.fetch(request.path)
    |> has_key?(request.verb)
    |> handle_request(swagger_paths, request)
  end

  defp has_key?(:error, _), do: false
  defp has_key?({:ok, map}, key), do: Map.has_key?(map, key)

  defp handle_request(true, swagger_paths, request), do: add_response(swagger_paths, request)
  defp handle_request(false, _swagger_paths, request), do: format_request(request)

  defp add_response(swagger_map, request) do
    original_request = swagger_map[request.path][request.verb]

    %{
      request.verb =>
        Map.put(
          original_request,
          "responses",
          Map.merge(original_request["responses"], Formatter.format_responses(request))
        )
    }
  end

  defp format_request(request) do
    operation =
      %{
        "summary" => Descriptor.get_action_description(request),
        "description" => Descriptor.get_request_description(request),
        "responses" => Formatter.format_responses(request)
      }
      |> put_parameters_if_needed(request)
      |> put_request_body_if_needed(request)
      |> put_security_if_needed(request)

    %{
      request.verb => operation
    }
  end

  defp put_parameters_if_needed(swagger, %{path_params: params} = request)
       when params not in [nil, %{}] do
    Map.put(swagger, "parameters", Formatter.format_parameters(request))
  end

  defp put_parameters_if_needed(swagger, _), do: swagger

  defp put_request_body_if_needed(swagger, %{request_body: body} = request)
       when body not in [nil, %{}] do
    Map.put(swagger, "requestBody", Formatter.format_body(request))
  end

  defp put_request_body_if_needed(swagger, _), do: swagger

  defp put_security_if_needed(swagger, %{header_params: headers}) do
    headers
    |> Enum.any?(fn {header, _} -> String.downcase(header) == "authorization" end)
    |> if do
      Map.put(swagger, "security", [%{"api_key" => []}])
    else
      swagger
    end
  end

  defp xcribe_info,
    do: apply(Config.xcribe_information_source(), :api_info, [])
end
