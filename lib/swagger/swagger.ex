defmodule Xcribe.Swagger do
  alias Xcribe.Config
  alias Xcribe.Swagger.{Descriptor, Formatter}

  def generate_doc(requests) do
    swagger_json()
    |> add_requests(requests)
    |> Jason.encode()
    |> (fn {:ok, resp} -> resp end).()
  end

  defp swagger_json() do
    %{
      "openapi" => "3.0.0",
      "info" => %{
        "title" => xcribe_info() |> Map.get(:name, ""),
        "version" => xcribe_info() |> Map.get(:version, "0.1.0"),
        "description" => xcribe_info() |> Map.get(:description, "")
      },
      "paths" => %{}
    }
  end

  defp add_requests(swagger_map, requests) do
    paths =
      Enum.reduce(requests, %{}, fn x, acc ->
        Map.put(acc, x.path, Map.merge(acc[x.path] || %{}, format_request(x)))
      end)

    Map.merge(swagger_map, %{"paths" => paths})
  end

  defp format_request(request) do
    operation =
      %{
        "description" => Descriptor.get_request_description(request),
        "responses" => Formatter.format_responses(request)
      }
      |> put_parameters_if_needed(request)
      |> put_request_body_if_needed(request)

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

  defp xcribe_info,
    do: apply(Config.xcribe_information_source(), :api_info, [])
end
