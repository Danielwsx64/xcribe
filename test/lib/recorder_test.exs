defmodule RecorderTest do
  use ExUnit.Case, async: true

  alias Xcribe.Request
  alias Xcribe.Recorder

  describe "save and get requests records" do
    test "use genserver to save and recover requests" do
      Recorder.start_link()

      request_one = %Request{description: "first request"}
      request_two = %Request{description: "second request"}

      Recorder.save(request_one)
      Recorder.save(request_two)

      assert Recorder.get_all() == [request_two, request_one]
    end
  end
end
