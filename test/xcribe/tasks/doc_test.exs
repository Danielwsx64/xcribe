defmodule Xcribe.Tasks.DocTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  alias Mix.Tasks.Xcribe.Doc
  alias Xcribe.Recorder
  alias Xcribe.Request.Error
  alias Xcribe.Support.RequestsGenerator

  @mix_test_default_opts [
    "--only",
    "xcribe_document",
    "--formatter",
    "Xcribe.Tasks.Formatter",
    "--max-failures",
    "1"
  ]

  defmodule FakeInformation do
    use Xcribe.Information
  end

  defmodule FakeEndpoint do
    def config(:otp_app), do: "fake_app"
  end

  defmodule FailFakeEndpoint do
    def config(:otp_app), do: "fail_fake_app"
  end

  defmodule FakeProject do
    def deps_paths, do: %{"fake_app" => "/tmp/fake_app"}
    def umbrella?, do: true
  end

  defmodule FakeProjectNonUmbrella do
    def umbrella?, do: false
  end

  describe "run/1" do
    test "run task" do
      io_output = capture_io(fn -> Doc.run([]) end)

      assert io_output =~ "starting capture requests"
      assert io_output =~ "starting doc generation"
      assert io_output =~ "Xcribe Task - finished"
    end
  end

  describe "run task" do
    setup do
      Recorder.pop_all()

      output = "/tmp/task_tests.doc"

      Application.put_env(:xcribe, Xcribe.Tasks.DocTest.FakeEndpoint,
        information_source: Xcribe.Tasks.DocTest.FakeInformation,
        output: output
      )

      File.rm(output)

      on_exit(fn ->
        Application.delete_env(:xcribe, Xcribe.Tasks.DocTest.FakeEndpoint)
      end)
    end

    test "run mix test and generate documentation" do
      mix_test_fun = fn opts ->
        assert opts == @mix_test_default_opts

        Recorder.add(%{
          RequestsGenerator.users_index()
          | endpoint: Xcribe.Tasks.DocTest.FakeEndpoint
        })
      end

      io_output = capture_io(fn -> Doc.run_task([], mix_test_fun, FakeProjectNonUmbrella) end)

      assert io_output =~ "starting capture requests"
      assert io_output =~ "starting doc generation"
      assert io_output =~ "documentation written in /tmp/task_tests.doc"
      assert io_output =~ "Xcribe Task - finished"
      assert File.exists?("/tmp/task_tests.doc")
      assert Recorder.pop_all() == %{errors: []}
    end

    test "run task with custom output and format" do
      mix_test_fun = fn opts ->
        assert opts == @mix_test_default_opts

        Recorder.add(%{
          RequestsGenerator.users_index()
          | endpoint: Xcribe.Tasks.DocTest.FakeEndpoint
        })
      end

      io_output =
        capture_io(fn ->
          Doc.run_task(
            ["--format", "api_blueprint", "--output", "/tmp/custom_output_task_test.doc"],
            mix_test_fun,
            FakeProjectNonUmbrella
          )
        end)

      assert io_output =~ "documentation written in /tmp/custom_output_task_test.doc"
      assert File.read!("/tmp/custom_output_task_test.doc") =~ "FORMAT: 1A"
      assert File.rm!("/tmp/custom_output_task_test.doc")
      assert Recorder.pop_all() == %{errors: []}
    end

    test "override path for umbrella apps" do
      mix_test_fun = fn opts ->
        assert opts == @mix_test_default_opts

        Recorder.add(%{
          RequestsGenerator.users_index()
          | endpoint: Xcribe.Tasks.DocTest.FakeEndpoint
        })
      end

      io_output = capture_io(fn -> Doc.run_task([], mix_test_fun, FakeProject) end)

      assert io_output =~ "documentation written in /tmp/fake_app/tmp/task_tests.doc"
      assert File.read!("/tmp/fake_app/tmp/task_tests.doc") =~ "securitySchemes"
      assert File.rm!("/tmp/fake_app/tmp/task_tests.doc")
      assert Recorder.pop_all() == %{errors: []}
    end

    test "keep path when cant find deps path for umbrella app" do
      output = "/tmp/task_tests.doc"

      Application.put_env(:xcribe, Xcribe.Tasks.DocTest.FailFakeEndpoint,
        information_source: Xcribe.Tasks.DocTest.FakeInformation,
        output: output
      )

      mix_test_fun = fn opts ->
        assert opts == @mix_test_default_opts

        Recorder.add(%{
          RequestsGenerator.users_index()
          | endpoint: Xcribe.Tasks.DocTest.FailFakeEndpoint
        })
      end

      io_output = capture_io(fn -> Doc.run_task([], mix_test_fun, FakeProject) end)

      Application.delete_env(:xcribe, Xcribe.Tasks.DocTest.FailFakeEndpoint)

      assert io_output =~ "documentation written in #{output}"
      assert File.read!(output) =~ "securitySchemes"
      assert File.rm!(output)
      assert Recorder.pop_all() == %{errors: []}
    end

    test "generate docs for a specific endpoint" do
      mix_test_fun = fn opts ->
        assert opts == @mix_test_default_opts ++ ["/tmp/fake_app"]

        Recorder.add(%{
          RequestsGenerator.users_index()
          | endpoint: Xcribe.Tasks.DocTest.FakeEndpoint
        })
      end

      io_output =
        capture_io(fn ->
          Doc.run_task(
            ["--endpoint", "Xcribe.Tasks.DocTest.FakeEndpoint"],
            mix_test_fun,
            FakeProject
          )
        end)

      assert io_output =~ "documentation written in /tmp/fake_app/tmp/task_tests.doc"
      assert File.read!("/tmp/fake_app/tmp/task_tests.doc") =~ "securitySchemes"
      assert File.rm!("/tmp/fake_app/tmp/task_tests.doc")
      assert Recorder.pop_all() == %{errors: []}
    end

    test "exit with error when fail to generate doc" do
      mix_test_fun = fn opts ->
        assert opts == @mix_test_default_opts

        Recorder.add(%Error{
          type: :parsing,
          message: "route not found",
          __meta__: %{
            call: %{
              description: "test name",
              file: __ENV__.file,
              line: __ENV__.line
            }
          }
        })
      end

      io_output =
        capture_io(fn ->
          try do
            Doc.run_task([], mix_test_fun, FakeProjectNonUmbrella)
          catch
            :exit, message -> assert message == {:shutdown, 1}
          end
        end)

      assert io_output =~ "starting capture requests"
      assert io_output =~ "starting doc generation"
      assert io_output =~ "Parsing and validation errors"
      assert io_output =~ "Xcribe Task - aborted"
      refute File.exists?("/tmp/task_tests.doc")
      assert Recorder.pop_all() == %{errors: []}
    end

    test "send to test's task ignored options" do
      mix_test_fun = fn opts ->
        assert opts == @mix_test_default_opts ++ ["/custom/file/path", "--other", "value"]
      end

      io_output =
        capture_io(fn ->
          Doc.run_task(["/custom/file/path", "--other", "value"], mix_test_fun, FakeProject)
        end)

      assert io_output =~ "Xcribe Task - finished"
    end

    test "invalid endpoint module" do
      assert capture_io(fn ->
               try do
                 Doc.run_task(["--endpoint", "InvalidEndpoint"])
               catch
                 :exit, message -> assert message == {:shutdown, 1}
               end
             end) =~ "Couldn't find a path to endpoint InvalidEndpoint"
    end

    test "when cant find otp_app path" do
      Application.put_env(:xcribe, Xcribe.Tasks.DocTest.FailFakeEndpoint,
        information_source: Xcribe.Tasks.DocTest.FakeInformation
      )

      assert capture_io(fn ->
               try do
                 Doc.run_task(
                   ["--endpoint", "Xcribe.Tasks.DocTest.FailFakeEndpoint"],
                   nil,
                   FakeProject
                 )
               catch
                 :exit, message ->
                   Application.delete_env(:xcribe, Xcribe.Tasks.DocTest.FailFakeEndpoint)
                   assert message == {:shutdown, 1}
               end
             end) =~ "Couldn't find a path to endpoint Xcribe.Tasks.DocTest.FailFakeEndpoint"
    end

    test "invalid format option" do
      assert capture_io(fn ->
               try do
                 Doc.run_task(["--format", "invalid"])
               catch
                 :exit, message -> assert message == {:shutdown, 1}
               end
             end) =~ "Xcribe doesn't support the configured documentation format"
    end
  end
end
