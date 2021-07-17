defmodule Xcribe.RecorderTest do
  use ExUnit.Case, async: false

  alias Xcribe.{Recorder, Request, Request.Error}

  setup do
    Recorder.pop_all()

    :ok
  end

  describe "add/1" do
    test "use genserver to save and recover requests and errors" do
      request_one = %Request{description: "first request", endpoint: "first_endpoint"}
      request_two = %Request{description: "second request", endpoint: "first_endpoint"}
      request_three = %Request{description: "third request", endpoint: "second_endpoint"}
      request_error = %Error{message: "some error"}

      Recorder.add(request_one)
      Recorder.add(request_two)
      Recorder.add(request_three)
      Recorder.add(request_error)

      assert :sys.get_state(Recorder) == %{
               :errors => [request_error],
               "first_endpoint" => [request_two, request_one],
               "second_endpoint" => [request_three]
             }
    end
  end

  describe "pop_all/0" do
    test "pop all registered errors and requests from state" do
      request_one = %Request{description: "first request", endpoint: "endpoint"}
      request_two = %Request{description: "second request", endpoint: "endpoint"}
      request_error = %Error{message: "some error"}

      Recorder.add(request_one)
      Recorder.add(request_two)
      Recorder.add(request_error)

      assert Recorder.pop_all() == %{
               :errors => [request_error],
               "endpoint" => [request_two, request_one]
             }

      assert :sys.get_state(Recorder) == %{errors: []}
    end
  end
end
