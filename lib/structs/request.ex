defmodule ApiBluefy.Structs.Request do
  defstruct [:name, :body, :resp_body, :status_code, headers: [], resp_headers: []]
end
