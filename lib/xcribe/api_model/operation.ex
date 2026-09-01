defmodule Xcribe.APIModel.Operation do
  @moduledoc false

  alias Xcribe.APIModel.{Body, Example, Merge, Parameter, Response}
  alias Xcribe.{ContentDecoder, Request}

  import Xcribe.Helpers.Formatter, only: [authorization: 1, content_type: 1]

  @parameter_locations [path_params: :path, query_params: :query, header_params: :header]

  defstruct [
    :verb,
    :path,
    :action,
    :controller,
    :resource,
    descriptions: [],
    tags: [],
    security: [],
    parameters: [],
    request_content: [],
    responses: [],
    examples: []
  ]

  def from_request(%Request{} = request, config) do
    {response_body, decode_error} = decode_response(request, config)

    %__MODULE__{
      verb: request.verb,
      path: request.path,
      action: request.action,
      controller: request.controller,
      resource: request.resource,
      descriptions: [request.description],
      tags: Enum.sort(request.groups_tags),
      security: security_for(request),
      parameters: parameters_for(request),
      request_content: request_content_for(request),
      responses: [response_for(request, response_body)],
      examples: [Example.from_request(request, response_body, decode_error)]
    }
  end

  def merge(%__MODULE__{} = base, %__MODULE__{} = new) do
    %{
      base
      | descriptions: unique_sorted(base.descriptions, new.descriptions),
        tags: unique_sorted(base.tags, new.tags),
        security: unique_sorted(base.security, new.security),
        parameters: merge_parameters(new.parameters, base.parameters),
        request_content: merge_content(base.request_content, new.request_content),
        responses:
          Merge.by_key(base.responses, new.responses, &Response.sort_key/1, &Response.merge/2),
        examples: base.examples |> Enum.concat(new.examples) |> Enum.sort_by(&Example.sort_key/1)
    }
  end

  def sort_key(%__MODULE__{verb: verb}), do: verb

  defp decode_response(%Request{resp_body: body, resp_headers: headers}, config) do
    headers
    |> content_type()
    |> decode_body(body, config)
  end

  defp decode_body(_content_type, body, _config) when body in ["", nil], do: {nil, nil}
  defp decode_body(nil, _body, _config), do: {nil, :missing_content_type}

  defp decode_body(content_type, body, config) do
    case ContentDecoder.decode(body, content_type, config) do
      {:ok, decoded} -> {decoded, nil}
      {:error, reason} -> {nil, reason}
    end
  end

  defp response_for(%Request{} = request, response_body) do
    Response.new(
      request.status_code,
      parameters_in(request.resp_headers, :header),
      response_content_for(request, response_body)
    )
  end

  defp response_content_for(_request, nil), do: []

  defp response_content_for(%Request{resp_headers: headers} = request, body),
    do: [Body.new(content_type(headers), Request.format_schema(request), body)]

  defp request_content_for(%Request{request_body: body}) when body == %{}, do: []

  defp request_content_for(%Request{header_params: headers, request_body: body} = request),
    do: [Body.new(content_type(headers), Request.format_req_schema(request), body)]

  defp parameters_for(%Request{} = request) do
    Enum.reduce(@parameter_locations, [], fn {field, location}, parameters ->
      request
      |> Map.fetch!(field)
      |> parameters_in(location)
      |> merge_parameters(parameters)
    end)
  end

  defp parameters_in(params, location),
    do: Enum.map(params, fn {name, value} -> Parameter.new(name, location, value) end)

  defp merge_parameters(new, base),
    do: Merge.by_key(base, new, &Parameter.sort_key/1, &Parameter.merge/2)

  defp merge_content(base, new),
    do: Merge.by_key(base, new, &Body.sort_key/1, &Body.merge/2)

  defp unique_sorted(base, new) do
    base
    |> Enum.concat(new)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp security_for(%Request{header_params: headers}) do
    headers
    |> authorization()
    |> security_kind()
  end

  defp security_kind(nil), do: []
  defp security_kind("Bearer" <> _rest), do: [:bearer]
  defp security_kind("Basic" <> _rest), do: [:basic]
  defp security_kind(_authorization), do: [:api_key]
end
