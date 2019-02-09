defmodule Xcribe.Structs.Request do
  defstruct [:name, :body, :resp_body, :status_code, :path, headers: [], resp_headers: []]
end
