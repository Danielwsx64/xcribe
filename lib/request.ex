defmodule Xcribe.Request do
  @moduledoc """
  The struct of a parsed request
  """

  defstruct [
    :action,
    :controller,
    :description,
    :path,
    :request_body,
    :resource,
    :resource_group,
    :resp_body,
    :status_code,
    :verb,
    header_params: [],
    resp_headers: [],
    path_params: %{},
    query_params: %{},
    params: %{}
  ]
end
