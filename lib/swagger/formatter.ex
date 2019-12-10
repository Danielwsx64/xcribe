defmodule Xcribe.Swagger.Formatter do
  alias Xcribe.Swagger.Descriptor

  def format_parameters(%{path_params: params, controller: controller, action: action}) do
    Enum.reduce(params, [], fn {name, value}, acc ->
      [
        %{
          "name" => name,
          "in" => "path",
          "description" => Descriptor.get_param_description(name, controller, action),
          "required" => true,
          "schema" => %{"type" => type_of(value)}
        }
        | acc
      ]
    end)
  end

  def format_body(%{request_body: body} = request) do
    %{
      "required" => true,
      "content" => %{
        Descriptor.get_content_type(request) => %{
          "schema" => %{
            "type" => "object",
            "properties" => format_body_params(body, request)
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

  defp format_body_params(body, request) when is_map(body) do
    body
    |> Map.to_list()
    |> format_params(request)
  end

  defp format_params([{name, value} | tail], %{controller: controller} = request) do
    Map.merge(
      %{
        name => %{
          "type" => type_of(value),
          "description" => Descriptor.get_attr_description(name, controller)
        }
      },
      format_params(tail, request)
    )
  end

  defp format_params([], _), do: %{}

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
      Descriptor.get_content_type(request) => %{
        "schema" =>
          body
          |> Jason.decode()
          |> handle_json_decode()
          |> format_response_body_schema()
      }
    }
  end

  defp handle_json_decode({:ok, any}), do: any
  defp handle_json_decode({:error, %{data: data}}), do: data

  defp format_response_body_schema(body) when is_bitstring(body) do
    %{
      "type" => "string",
      "example" => body
    }
  end

  defp format_response_body_schema(body) when is_map(body) do
    %{
      "type" => "object",
      "properties" => format_body_params(body, %{controller: nil})
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
end
