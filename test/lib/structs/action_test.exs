defmodule Xcribe.Structs.ActionTest do
  use ExUnit.Case, async: true

  alias Xcribe.Structs.Action

  describe "struct keys" do
    test "have keys" do
      assert %{name: nil, verb: nil, paramters: [], requests: []} = %Action{}
    end
  end
end
