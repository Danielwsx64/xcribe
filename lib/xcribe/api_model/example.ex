defmodule Xcribe.APIModel.Example do
  @moduledoc false

  alias Xcribe.Helpers.Formatter
  alias Xcribe.Request

  defstruct [
    :__meta__,
    :description,
    :status,
    :request_content_type,
    :request_schema_name,
    :response_content_type,
    :response_schema_name,
    :response_raw_body,
    :response_body,
    :response_decode_error,
    path_params: %{},
    query_params: %{},
    request_headers: [],
    request_body: %{},
    response_headers: []
  ]

  def from_request(%Request{} = request, response_body, response_decode_error) do
    %__MODULE__{
      __meta__: request.__meta__,
      description: request.description,
      status: request.status_code,
      path_params: request.path_params,
      query_params: request.query_params,
      request_content_type: Formatter.content_type(request.header_params),
      # The consumer-declared names, not the synthesized ones every Body carries: API Blueprint has
      # no component section, so a name reaches its document only as a JSON Schema title, and a
      # schema the consumer never named must stay untitled.
      request_schema_name: request.req_schema,
      response_schema_name: request.schema,
      request_headers: Enum.sort(request.header_params),
      # A Plug.Conn never keeps the raw request body, only the parsed `body_params`, so the request
      # side has nothing to pair with `response_raw_body`. The response is the other way around:
      # `resp_body` is the binary as sent, and the decoded value is derived from it here.
      request_body: request.request_body,
      response_content_type: Formatter.content_type(request.resp_headers),
      response_headers: Enum.sort(request.resp_headers),
      response_raw_body: request.resp_body,
      response_body: response_body,
      response_decode_error: response_decode_error
    }
  end

  def sort_key(%__MODULE__{description: description, status: status} = example) do
    {file, line} = Request.document_location(example)

    {status, description, file, line}
  end
end
