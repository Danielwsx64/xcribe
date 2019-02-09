defmodule Xcribe.Structs.ParsedRequestTest do
  use ExUnit.Case, async: true

  alias Xcribe.Structs.ParsedRequest

  describe "struct keys" do
    test "have keys" do
      assert %{
               resource_group: nil,
               resource: nil,
               action: nil,
               path: nil,
               verb: nil,
               params: nil,
               header_params: nil,
               query_params: nil,
               path_params: nil,
               request_body: nil,
               resp_headers: nil,
               resp_body: nil,
               status_code: nil
             } = %ParsedRequest{}
    end
  end
end
