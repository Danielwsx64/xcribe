defmodule ApiBluefy.Structs.ParsedRequest do
  defstruct [
    :resource_group,
    :resource,
    :action,
    :name,
    :body,
    :resp_body,
    paramters: [],
    headers: [],
    resp_headers: []
  ]
end
