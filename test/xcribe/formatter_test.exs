defmodule Xcribe.FormatterTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  alias Xcribe.{Formatter, Recorder}

  describe "init/1" do
    test "return active false" do
      assert Formatter.init([]) == {:ok, active?: false}
    end

    test "return active true by env var" do
      Application.put_env(:xcribe, :env_var, "PWD")

      assert Formatter.init([]) == {:ok, active?: true}
    end
  end

  describe "handle suite_finished callback" do
    setup do
      Application.put_env(:xcribe, :output, "/tmp/test")
      Application.put_env(:xcribe, :information_source, Xcribe.Support.Information)
      Application.put_env(:xcribe, :format, :swagger)
      Application.delete_env(:xcribe, :json_library)
      Recorder.pop_all()

      on_exit(fn ->
        Application.delete_env(:xcribe, :output)
        Application.delete_env(:xcribe, :information_source)
        Application.delete_env(:xcribe, :env_var)
      end)
    end

    test "write documentation when is active" do
      status = [active?: true]

      assert capture_io(fn ->
               assert Formatter.handle_cast({:suite_finished, 1, 2}, status) ==
                        {:noreply, :ok}
             end) =~ "Xcribe documentation written in /tmp/test"
    end

    test "ignore suite_finished when is not active" do
      status = [active?: false]

      assert capture_io(fn ->
               assert Formatter.handle_cast({:suite_finished, 1, 2}, status) ==
                        {:noreply, status}
             end) == ""
    end
  end

  test "for ExUnit =< 1.11" do
    capture_io(fn ->
      assert Formatter.handle_cast({:suite_finished, 1, 2}, active?: true) == {:noreply, :ok}
    end) =~ "Xcribe documentation written in /tmp/test"
  end

  test "for ExUnit =~ 1.12" do
    capture_io(fn ->
      assert Formatter.handle_cast(
               {:suite_finished, %{run: 1, async: 2, load: 3}},
               active?: true
             ) ==
               {:noreply, :ok}
    end) =~ "Xcribe documentation written in /tmp/test"
  end

  test "unexpected event" do
    assert Formatter.handle_cast({:other_event}, nil) == {:noreply, nil}
  end
end
