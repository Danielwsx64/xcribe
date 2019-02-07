defmodule ApiBluefy.Structs.ActionTest do
  use ExUnit.Case, async: true

  alias ApiBluefy.Structs.Action

  describe "struct keys" do
    test "have keys" do
      assert %{name: nil, verb: nil, paramters: [], requests: []} = %Action{}
    end
  end
end
