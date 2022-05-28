defmodule Xcribe.Swagger.Formatter do
  @moduledoc false

  alias Plug.Upload
  alias Xcribe.{ContentDecoder, JsonSchema, Request}

  import Xcribe.Helpers.Formatter, only: [content_type: 1, authorization: 1]

  @doc """
  Return an empty struct of an OpenAPI Object.
  """
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
            security: security_requirement_object_by_request(request),
            tags: request.groups_tags
          }
        )
    }
  end

  @doc """
  Return a Request Body Object from given request
  """
  def request_body_object_from_request(%Request{header_params: headers, request_body: body}) do
    headers
    |> content_type()
    |> media_type_object(body)
  end

  @doc """
  Return a Response Object from given request
  """
  def response_object_from_request(%Request{
        __meta__: meta,
        resp_headers: headers,
        resp_body: body
      }) do
    content_type = content_type(headers)

    content_type
    |> media_type_object(response_content(body, content_type, meta.config))
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

  @doc """
  Merge two lists of parameter object keep uniq names
  """
  def merge_parameter_object_lists(base_list, new_list, mode \\ :keep) do
    new_list
    |> Enum.reduce(base_list, &merge_parameter_func(&1, &2, mode))
    |> Enum.sort(&(&1.name < &2.name))
  end

  @doc """
  Merge two path item objects
  """
  def merge_path_item_objects(base, new_item, verb) do
    Map.update(
      base,
      verb,
      new_item[verb],
      &merge_path_items(&1, new_item[verb])
    )
  end

  defp merge_path_items(base, %{parameters: params, responses: resp} = new_item) do
    mode = overwrite_mode(resp)

    base
    |> Map.update(:parameters, params, &merge_parameter_object_lists(&1, params, mode))
    |> Map.update(:responses, resp, &Map.merge(&1, resp))
    |> merge_request_body_if_needed(new_item, mode)
  end

  defp overwrite_mode(responses) do
    code = responses |> Map.keys() |> List.first()

    if code >= 200 and code < 300, do: :overwrite, else: :keep
  end

  defp merge_request_body_if_needed(%{requestBody: _body} = item, %{requestBody: new}, mode) do
    Map.update(
      item,
      :requestBody,
      new,
      &%{description: "", content: merge_request_body(&1, new, mode)}
    )
  end

  defp merge_request_body_if_needed(item, %{requestBody: body}, _mode),
    do: Map.put(item, :requestBody, body)

  defp merge_request_body_if_needed(item, _new_item, _mode), do: item

  defp merge_request_body(body, new_body, :keep), do: Map.merge(new_body.content, body.content)

  defp merge_request_body(body, new_body, :overwrite),
    do: Map.merge(body.content, new_body.content)

  defp merge_parameter_func(new_param, params, :keep) do
    if has_param?(new_param, params), do: params, else: [new_param | params]
  end

  defp merge_parameter_func(new_param, params, :overwrite) do
    [new_param | drop_eql_param(new_param, params)]
  end

  defp drop_eql_param(param, params), do: Enum.reject(params, &eql_name_and_in(&1, param))

  defp has_param?(param, params), do: Enum.any?(params, &eql_name_and_in(&1, param))

  defp eql_name_and_in(%{name: name, in: inn}, %{name: name, in: inn}), do: true
  defp eql_name_and_in(_base_param, _new_param), do: false

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

  defp media_type_object(_media_type, ""), do: %{description: ""}

  defp media_type_object(media_type, content) do
    media_type_schema =
      %{}
      |> Map.put(:schema, JsonSchema.schema_for(content, title: false, example: true))
      |> add_enconding_if_needed(content)

    %{description: "", content: %{media_type => media_type_schema}}
  end

  defp response_content("", _content_type, _config), do: ""

  defp response_content(body, "application/json", config) when is_binary(body),
    do: ContentDecoder.decode!(body, "application/json", config)

  defp response_content(body, _content_type, _config), do: body

  defp add_enconding_if_needed(schema, content) when is_map(content) do
    content
    |> Map.keys()
    |> Enum.reduce(schema, &enconding_for(content[&1], &2, &1))
  end

  defp add_enconding_if_needed(schema, _content), do: schema

  defp enconding_for(%Upload{} = upload, schema, property) do
    encoding = %{property => %{contentType: upload.content_type}}

    Map.update(schema, :encoding, encoding, &Map.merge(&1, encoding))
  end

  defp enconding_for(_value, schema, _property), do: schema

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
      %{description: "", schema: JsonSchema.schema_for({title, value}, title: false)}
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
