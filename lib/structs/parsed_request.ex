defmodule Xcribe.Structs.ParsedRequest do
  defstruct [
    :resource_group,
    :resource,
    :action,
    :path,
    :verb,
    :params,
    :header_params,
    :query_params,
    :path_params,
    :request_body,
    :resp_headers,
    :resp_body,
    :status_code
  ]
end
