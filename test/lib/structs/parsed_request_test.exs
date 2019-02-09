defmodule Xcribe.Structs.ParsedRequestTest do
  use ExUnit.Case, async: true

  alias Xcribe.Structs.ParsedRequest

  describe "struct keys" do
    test "have keys" do
      assert %{
               resource_group: nil,
               resource: nil,
               action: nil,
               action_verb: nil,
               name: nil,
               paramters: [],
               body: nil,
               headers: [],
               resp_body: nil,
               resp_headers: [],
               status_code: nil,
               path: nil
             } = %ParsedRequest{}
    end
  end
end
