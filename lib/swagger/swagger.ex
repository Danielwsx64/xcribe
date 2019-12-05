defmodule Xcribe.Swagger do
  alias Xcribe.Config

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
    paths = Enum.reduce(requests, %{}, fn x, acc ->
        Map.put(acc, x.path, Map.merge(acc[x.path] || %{}, format_request(x)))
      end)

    Map.merge(swagger_map, %{"paths" => paths})
  end

  defp format_request(request) do
    operation =
      %{
        "description" => request.description,
        "responses" => format_responses(request)
      }
      |> put_parameters_if_needed(request)
      |> put_request_body_if_needed(request)

    %{
      request.verb => operation
    }
  end

  defp put_parameters_if_needed(swagger, %{path_params: params}) when params not in [nil, %{}] do
    Map.put(swagger, "parameters", format_paramseters(params))
  end

  defp put_parameters_if_needed(swagger, _), do: swagger

  defp put_request_body_if_needed(swagger, %{request_body: body} = request)
       when body not in [nil, %{}] do
    Map.put(swagger, "requestBody", format_body(request))
  end

  defp put_request_body_if_needed(swagger, _), do: swagger

  defp format_paramseters(params) do
    Enum.reduce(params, [], fn {p, v}, acc ->
      [
        %{
          "name" => p,
          "in" => "path",
          "required" => true,
          "schema" => %{"type" => type_of(v)}
        }
        | acc
      ]
    end)
  end

  defp format_body(%{request_body: body} = request) do
    %{
      "required" => true,
      "content" => %{
        get_content_type(request) => %{
          "schema" => %{
            "type" => "object",
            "properties" => format_body_params(body)
          }
        }
      }
    }
  end

  defp format_body_params(body) when is_map(body) do
    body
    |> Map.to_list()
    |> format_params()
  end

  defp format_body_params(body) when is_list(body) do
    Enum.map(body, &format_body_params/1)
  end

  defp format_params([{name, value} | tail]) do
    Map.merge(
      %{
        name => %{"type" => type_of(value)}
      },
      format_params(tail)
    )
  end

  defp format_params([]), do: %{}

  defp format_responses(request) do
    %{
      request.status_code => %{
        "description" => "Success", # TODO
        "headers" => format_headers(request.resp_headers),
        "content" => format_response_body(request)
      }
    }
  end

  defp format_headers([{name, value} | tail]) do
    Map.merge(
      %{
        name => %{"schema" => %{"type" => type_of(value)}}
      },
      format_headers(tail)
    )
  end

  defp format_headers([]), do: %{}

  defp format_response_body(%{resp_body: body} = request) do
    %{
      get_content_type(request) => %{
        "schema" => body |> Jason.decode!() |> format_response_body_schema()
      }
    }
  end

  defp format_response_body_schema(body) when is_map(body) do
    %{
      "type" => "object",
      "properties" => format_body_params(body)
    }
  end

  defp format_response_body_schema(body) when is_list(body) do
    %{
      "type" => "array",
      "items" => body |> List.first() |> format_response_body_schema()
    }
  end

  defp type_of(value) when is_integer(value), do: "integer"
  defp type_of(_), do: "string"

  # TODO
  defp get_content_type(_), do: "application/json"

  defp resource_description(%{controller: controller}),
    do: apply(Config.xcribe_information_source(), :resource_description, [controller])

  defp resource_parameters(%{controller: controller}),
    do: apply(Config.xcribe_information_source(), :resource_parameters, [controller])

  defp resource_attributes(%{controller: controller}),
    do: apply(Config.xcribe_information_source(), :resource_attributes, [controller])

  defp action_description(%{controller: controller, action: action}),
    do: apply(Config.xcribe_information_source(), :action_description, [controller, action])

  defp xcribe_info,
    do: apply(Config.xcribe_information_source(), :api_info, [])
end
