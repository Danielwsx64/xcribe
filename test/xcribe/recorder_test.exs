defmodule Xcribe.RecorderTest do
  use ExUnit.Case, async: false

  alias Xcribe.{Recorder, Request, Request.Error}

  setup do
    Recorder.pop_all()
    Recorder.set_active(false)

    on_exit(fn ->
      System.delete_env("XCRIBE_ENV")
    end)
  end

  describe "init/1" do
    test "return active false" do
      assert Recorder.init([]) == {:ok, %{active?: false, records: %{errors: []}}}
    end

    test "return active true by env var" do
      System.put_env("XCRIBE_ENV", "asdf")
      assert Recorder.init([]) == {:ok, %{active?: true, records: %{errors: []}}}
    end
  end

  describe "active?/0" do
    test "return true when is active" do
      Recorder.set_active(true)
      assert Recorder.active?() == true
    end

    test "return false when not active" do
      assert Recorder.active?() == false
    end
  end

  describe "set_active/1" do
    test "set active value" do
      assert Recorder.set_active(true) == :ok
      assert :sys.get_state(Recorder) == %{active?: true, records: %{errors: []}}
    end
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
               active?: false,
               records: %{
                 :errors => [request_error],
                 "first_endpoint" => [request_two, request_one],
                 "second_endpoint" => [request_three]
               }
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

      assert :sys.get_state(Recorder) == %{active?: false, records: %{errors: []}}
    end
  end
end
