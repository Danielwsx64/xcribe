defmodule ApiBluefy.Structs.ParsedRequest do
  defstruct [
    :resource_group,
    :resource,
    :action,
    :name,
    :body,
    :resp_body,
    :status_code,
    :path,
    paramters: [],
    headers: [],
    resp_headers: []
  ]
end
