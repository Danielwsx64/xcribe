defmodule Xcribe.Request do
  @moduledoc false

  defstruct [
    :__meta__,
    :action,
    :controller,
    :description,
    :endpoint,
    :path,
    :request_body,
    :resource,
    :resp_body,
    :status_code,
    :verb,
    header_params: [],
    resp_headers: [],
    path_params: %{},
    query_params: %{},
    params: %{},
    groups_tags: []
  ]
end
