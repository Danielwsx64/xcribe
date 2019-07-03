defmodule Xcribe.Structs.ParsedRequestTest do
  use ExUnit.Case, async: true

  alias Xcribe.Structs.ParsedRequest

  describe "struct keys" do
    test "have keys" do
      struct = Map.from_struct(%ParsedRequest{})

      expected_struct = %{
        action: nil,
        controller: nil,
        description: nil,
        header_params: nil,
        params: nil,
        path: nil,
        path_params: nil,
        query_params: nil,
        request_body: nil,
        resource: nil,
        resource_group: nil,
        resp_body: nil,
        resp_headers: nil,
        status_code: nil,
        verb: nil
      }

      assert struct == expected_struct
    end
  end
end
