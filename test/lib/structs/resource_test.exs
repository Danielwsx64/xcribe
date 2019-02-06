defmodule ApiBluefy.Structs.ResourceTest do
  use ExUnit.Case, async: true

  alias ApiBluefy.Structs.Resource

  describe "struct keys" do
    test "have keys" do
      assert %{name: nil, actions: []} = %Resource{}
    end
  end
end
