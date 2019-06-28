defmodule Xcribe.Structs.ParsedRequest do
  defstruct [
    :action,
    :controller,
    :header_params,
    :params,
    :path,
    :path_params,
    :query_params,
    :request_body,
    :resource,
    :resource_group,
    :resp_body,
    :resp_headers,
    :status_code,
    :verb
  ]
end
