defmodule ApiBluefy.Structs.ParsedRequestTest do
  use ExUnit.Case, async: true

  alias ApiBluefy.Structs.ParsedRequest

  describe "struct keys" do
    test "have keys" do
      assert %{
               resource_group: nil,
               resource: nil,
               action: nil,
               paramters: [],
               name: nil,
               body: nil,
               headers: [],
               resp_body: nil,
               resp_headers: []
             } = %ParsedRequest{}
    end
  end
end
