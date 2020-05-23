defmodule RecorderTest do
  use ExUnit.Case, async: true

  alias Xcribe.{Recorder, Request, Request.Error}

  describe "save and get requests records" do
    test "use genserver to save and recover requests" do
      Recorder.start_link()

      request_one = %Request{description: "first request"}
      request_two = %Request{description: "second request"}
      request_error = %Error{message: "some error"}

      Recorder.save(request_one)
      Recorder.save(request_two)
      Recorder.save(request_error)

      assert Recorder.get_all() == [request_error, request_two, request_one]
    end
  end
end
