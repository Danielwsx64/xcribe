defmodule Xcribe.Request.ErrorTest do
  use ExUnit.Case, async: true

  alias Xcribe.Request.Error

  test "struct" do
    struct = Map.from_struct(%Error{})

    expected_struct = %{
      __meta__: nil,
      message: nil,
      type: nil
    }

    assert struct == expected_struct
  end
end
