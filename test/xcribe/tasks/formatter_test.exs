defmodule Xcribe.Tasks.FormatterTest do
  use ExUnit.Case, async: true

  import ExUnit.CaptureIO

  alias Xcribe.Tasks.Formatter

  describe "init/1" do
    test "initialize using ExUnit.CLIFormatter" do
      ex_unit_opts = [
        include: [:xcribe_document],
        exclude: [:test],
        max_cases: 8,
        seed: 92_619,
        autorun: false,
        after_suite: [],
        capture_log: false,
        formatters: [Xcribe.Tasks.Formatter],
        timeout: 60_000,
        trace: false,
        failures_manifest_file: "/.mix_test_failures",
        max_failures: 1,
        assert_receive_timeout: 100,
        refute_receive_timeout: 100,
        colors: [],
        stacktrace_depth: 20,
        slowest: 0
      ]

      capture_io(fn ->
        result = Formatter.init(ex_unit_opts)

        assert {:ok,
                %{
                  colors: _any,
                  excluded_counter: 0,
                  failure_counter: 0,
                  invalid_counter: 0,
                  seed: 92_619,
                  skipped_counter: 0,
                  slowest: 0,
                  test_counter: %{},
                  test_timings: [],
                  trace: false,
                  width: 80
                }} = result
      end)
    end
  end

  describe "handle_cast/2" do
    test "handle a success test finished" do
      fake_test = %{name: :"test fake", time: 1000, state: nil}

      assert capture_io(fn ->
               assert Formatter.handle_cast({:test_finished, fake_test}, %{}) ==
                        {:noreply, %{}}
             end) == "\e[32m┃\e[0m fake - 0.00s\n"
    end

    test "handle teste error finished with ExUnit.CLIFormatter" do
      fake_test = %ExUnit.Test{
        name: :"test do something",
        state:
          {:failed,
           [
             {:error, %RuntimeError{message: "daniel"},
              [
                {TesteApiWeb.PageControllerTest, :"test do something", 1,
                 [
                   file: 'test/teste_api_web/controllers/page_controller_test.exs',
                   line: 13
                 ]}
              ]}
           ]},
        tags: %{
          file: "page_controller_test.exs",
          test_type: :test
        }
      }

      state = %{
        colors: [enabled: true],
        failure_counter: 0,
        test_counter: %{},
        test_timings: [],
        trace: false,
        width: 272
      }

      assert captured =
               capture_io(fn ->
                 assert Formatter.handle_cast({:test_finished, fake_test}, state) ==
                          {:noreply, state}
               end)

      assert captured =~ "Test error: do something"
      assert captured =~ "doc tasks was aborted"
    end

    test "ignore other events" do
      assert capture_io(fn ->
               assert Formatter.handle_cast("fake event", []) == {:noreply, []}
             end) == ""
    end
  end
end
