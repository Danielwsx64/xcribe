defmodule ApiBluefy.Structs.ResourceGroupTest do
  use ExUnit.Case, async: true

  alias ApiBluefy.Structs.ResourceGroup

  describe "struct keys" do
    test "have keys" do
      assert %{name: nil, resources: []} = %ResourceGroup{}
    end
  end
end
