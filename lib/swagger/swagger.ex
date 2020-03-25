defmodule Xcribe.Swagger do
  @moduledoc """
  Treats list of Requests and generates OpenAPI 3.0 JSON
  """

  alias Xcribe.{Config, JSON}
  alias Xcribe.Swagger.{Descriptor, Formatter}

  @empty_data [nil, %{}, []]
  @security_scheme %{
    "securitySchemes" => %{
      "api_key" => %{"name" => "Authorization", "type" => "apiKey", "in" => "header"}
    }
  }

  def generate_doc(requests) do
    requests
    |> build_openapi_object()
    |> include_security_scheme(requests)
    |> json_encode!()
  end

  defp build_openapi_object(requests) do
    %{
      "openapi" => "3.0.0",
      "info" => %{
        "title" => Map.get(xcribe_info(), :name, ""),
        "version" => Map.get(xcribe_info(), :version, "0.1.0"),
        "description" => Map.get(xcribe_info(), :description, "")
      },
      "paths" => requests |> Enum.sort_by(& &1.status_code) |> paths_from_requests()
    }
  end

  defp paths_from_requests(requests),
    do: Enum.reduce(requests, %{}, &include_request_into_paths/2)

  defp include_request_into_paths(%{path: path} = request, paths) do
    Map.update(
      paths,
      path,
      build_path_item_object(request),
      &include_request_into_given_path(&1, request)
    )
  end

  defp include_request_into_given_path(path, %{verb: verb} = request) do
    Map.update(
      path,
      verb,
      build_operation_object(request),
      &include_request_into_given_verb(&1, request)
    )
  end

  defp include_request_into_given_verb(operation_object, request) do
    Map.update(operation_object, "responses", %{}, fn responses ->
      Map.merge(responses, Formatter.format_responses(request))
    end)
  end

  defp build_path_item_object(%{verb: verb} = request),
    do: %{verb => build_operation_object(request)}

  defp build_operation_object(request) do
    request
    |> base_operation_object
    |> parameters_if_needed(request)
    |> request_body_if_needed(request)
    |> security_if_needed(request)
  end

  defp base_operation_object(request) do
    %{
      "summary" => Descriptor.get_action_description(request),
      "description" => Descriptor.get_request_description(request),
      "responses" => Formatter.format_responses(request)
    }
  end

  defp include_security_scheme(openapi_object, requests) do
    requests
    |> Enum.any?(&has_authorization_header?/1)
    |> put_security_scheme(openapi_object)
  end

  defp put_security_scheme(false, openapi_object), do: openapi_object

  defp put_security_scheme(true, openapi_object),
    do: Map.put(openapi_object, "components", @security_scheme)

  defp has_authorization_header?(request) do
    request
    |> Map.fetch!(:header_params)
    |> Enum.any?(fn {h, _} -> String.match?(h, ~r/^authorization$/i) end)
  end

  defp parameters_if_needed(openapi_object, request) do
    request
    |> Map.take([:path_params, :query_params, :header_params])
    |> Enum.any?(&(elem(&1, 1) not in @empty_data))
    |> include_parameters(openapi_object, request)
  end

  defp include_parameters(false, openapi_object, _request), do: openapi_object

  defp include_parameters(true, openapi_object, request) do
    Map.put(openapi_object, "parameters", Formatter.request_parameters(request))
  end

  defp request_body_if_needed(openapi_object, %{request_body: body}) when body in @empty_data,
    do: openapi_object

  defp request_body_if_needed(openapi_object, request) do
    Map.put(openapi_object, "requestBody", Formatter.request_body(request))
  end

  defp security_if_needed(openapi_object, request) do
    if has_authorization_header?(request) do
      Map.put(openapi_object, "security", [%{"api_key" => []}])
    else
      openapi_object
    end
  end

  defp json_encode!(map), do: JSON.encode!(map)

  defp xcribe_info, do: apply(Config.xcribe_information_source(), :api_info, [])
end
