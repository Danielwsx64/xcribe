defmodule Xcribe.Structs.SwaggerDataTest do
  use ExUnit.Case, async: true

  alias Xcribe.Structs.SwaggerData

  describe "struct keys" do
    test "have keys" do
      assert %{paths: %{}} = %SwaggerData{}
    end
  end
end
