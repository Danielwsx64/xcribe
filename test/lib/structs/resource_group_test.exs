defmodule Xcribe.Structs.ResourceGroupTest do
  use ExUnit.Case, async: true

  alias Xcribe.Structs.ResourceGroup

  describe "struct keys" do
    test "have keys" do
      assert %{name: nil, resources: []} = %ResourceGroup{}
    end
  end
end
