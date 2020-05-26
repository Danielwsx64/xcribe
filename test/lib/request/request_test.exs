defmodule Xcribe.RequestTest do
  use ExUnit.Case, async: true

  alias Xcribe.Request

  describe "struct keys" do
    test "have keys" do
      struct = Map.from_struct(%Request{})

      expected_struct = %{
        __meta__: nil,
        action: nil,
        controller: nil,
        description: nil,
        header_params: [],
        params: %{},
        path: nil,
        path_params: %{},
        query_params: %{},
        request_body: nil,
        resource: nil,
        resource_group: nil,
        resp_body: nil,
        resp_headers: [],
        status_code: nil,
        verb: nil
      }

      assert struct == expected_struct
    end
  end
end
