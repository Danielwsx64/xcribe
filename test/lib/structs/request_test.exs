defmodule ApiBluefy.Structs.RequestTest do
  use ExUnit.Case, async: true

  alias ApiBluefy.Structs.Request

  describe "struct keys" do
    test "have keys" do
      assert %{
               name: nil,
               body: nil,
               headers: [],
               resp_body: nil,
               resp_headers: [],
               status_code: nil
             } = %Request{}
    end
  end
end
