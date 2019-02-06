defmodule ApiBluefy.Structs.Request do
  defstruct [:name, :body, :resp_body, headers: [], resp_headers: []]
end
