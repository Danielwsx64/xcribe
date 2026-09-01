defmodule Xcribe.Swagger.Formatter do
  @moduledoc false

  alias Xcribe.APIModel
  alias Xcribe.APIModel.{Body, Operation, Parameter, Response}
  alias Xcribe.Schema

  @json_content_type "application/json"
  @ignored_header_parameters ["content-type", "authorization", "accept"]

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

  @doc """
  Build the Operation Object of one operation of the API model.
  """
  def operation_object(%Operation{} = operation) do
    object = %{
      description: List.first(operation.descriptions),
      responses: responses_object(operation.responses),
      parameters: parameter_objects(operation.parameters),
      security: Enum.map(operation.security, &%{&1 => []}),
      tags: operation.tags
    }

    add_request_body(object, operation.request_content)
  end

  @doc """
  Build the Components Object, with the schemas of the specification file as the base so a hand
  written component survives alongside the generated ones.

  Only the schemas an operation actually references are emitted. The model registers a name for
  every body it saw, including bodies no `$ref` will ever point at, like a plain text response.
  """
  def components_object(%APIModel{} = model, specification) do
    %{
      schemas:
        Schema.merge(specification.schemas, Map.take(model.schemas, referenced_names(model))),
      securitySchemes: Map.new(model.security_schemes, &security_scheme_object/1)
    }
  end

  defp add_request_body(object, []), do: object

  defp add_request_body(object, request_content),
    do: Map.put(object, :requestBody, %{content: content_object(request_content)})

  defp responses_object(responses), do: Map.new(responses, &response_object/1)

  defp response_object(%Response{} = response) do
    object = %{description: "", headers: headers_object(response.headers)}

    {response.status, add_content(object, described_content(response.content))}
  end

  defp add_content(object, []), do: object
  defp add_content(object, content), do: Map.put(object, :content, content_object(content))

  # Only a response served as exactly `application/json` is described, which is what the format did
  # before the model existed. Every response reaches the model, including the plain text ones, so
  # the restriction belongs here rather than in the model.
  defp described_content(content),
    do: Enum.filter(content, &(&1.content_type == @json_content_type))

  # Grouping by content type cannot make the output order dependent: the bodies of one content type
  # arrive already sorted from APIModel.Merge.by_key/4, and the `oneOf` list below is sorted again.
  defp content_object(bodies) do
    bodies
    |> Enum.group_by(& &1.content_type)
    |> Map.new(fn {content_type, of_type} ->
      {content_type, %{schema: schema_object(of_type)}}
    end)
  end

  defp schema_object([body]), do: reference_for(body)

  defp schema_object(bodies),
    do: %{oneOf: bodies |> Enum.map(&reference_for/1) |> Enum.uniq() |> Enum.sort()}

  defp reference_for(%Body{schema_name: name, collection: true}),
    do: %{type: "array", items: reference_object(name)}

  defp reference_for(%Body{schema_name: name}), do: reference_object(name)

  defp reference_object(name), do: %{"$ref" => "#/components/schemas/#{name}"}

  defp parameter_objects(parameters) do
    parameters
    |> Enum.reject(&ignored_parameter?/1)
    |> Enum.sort_by(&{&1.name, &1.location})
    |> Enum.map(&parameter_object/1)
  end

  defp ignored_parameter?(%Parameter{location: :header, name: name}),
    do: name in @ignored_header_parameters

  defp ignored_parameter?(%Parameter{}), do: false

  defp parameter_object(%Parameter{} = parameter) do
    object = %{
      name: parameter.name,
      in: to_string(parameter.location),
      schema: parameter.schema,
      example: List.first(parameter.examples)
    }

    add_required(object, parameter.required)
  end

  defp add_required(object, true), do: Map.put(object, :required, true)
  defp add_required(object, false), do: object

  defp headers_object(headers) do
    headers
    |> Enum.reject(&(&1.name == "content-type"))
    |> Map.new(&{&1.name, %{schema: &1.schema}})
  end

  defp referenced_names(%APIModel{routes: routes}) do
    routes
    |> Enum.flat_map(& &1.operations)
    |> Enum.flat_map(&referenced_names_of/1)
    |> Enum.uniq()
  end

  defp referenced_names_of(%Operation{} = operation) do
    Enum.map(operation.request_content, & &1.schema_name) ++
      Enum.flat_map(operation.responses, &response_schema_names/1)
  end

  defp response_schema_names(%Response{content: content}),
    do: content |> described_content() |> Enum.map(& &1.schema_name)

  defp security_scheme_object(:api_key),
    do: {"api_key", %{type: "apiKey", name: "authorization", in: "header"}}

  defp security_scheme_object(:bearer),
    do: {"bearer", %{type: "http", scheme: "bearer", bearerFormat: "JWT"}}

  defp security_scheme_object(:basic), do: {"basic", %{type: "http", scheme: "basic"}}
end
