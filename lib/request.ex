defmodule Xcribe.Request do
  @moduledoc """
  The struct of a parsed request
  """

  defstruct [
    :action,
    :controller,
    :description,
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
