defmodule XcribeTest do
  use ExUnit.Case

  alias Xcribe.Recorder

  test "start Xcribe" do
    {:ok, _} = Xcribe.start([], [])

    assert Recorder.get_all() == []
  end
end
