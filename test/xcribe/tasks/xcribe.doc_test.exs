defmodule Tasks.Xcribe.DocTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  alias Mix.Tasks.Xcribe.Doc
  alias Xcribe.Recorder
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

  describe "run task" do
    setup do
      Recorder.pop_all()

      output = "/tmp/task_tests.doc"

      Application.put_env(:xcribe, Tasks.Xcribe.DocTest.FakeEndpoint,
        information_source: Tasks.Xcribe.DocTest.FakeInformation,
        output: output
      )

      File.rm(output)

      on_exit(fn ->
        Application.delete_env(:xcribe, Tasks.Xcribe.DocTest.FakeEndpoint)
      end)
    end

    test "run mix test and generate documentation" do
      mix_test_fun = fn opts ->
        assert opts == @mix_test_default_opts

        Recorder.add(%{
          RequestsGenerator.users_index()
          | endpoint: Tasks.Xcribe.DocTest.FakeEndpoint
        })
      end

      output = capture_io(fn -> Doc.run_task([], mix_test_fun, FakeProjectNonUmbrella) end)

      assert output =~ "starting capture requests"
      assert output =~ "starting doc generation"
      assert output =~ "documentation written in /tmp/task_tests.doc"
      assert output =~ "Xcribe Task - finished"
      assert File.exists?("/tmp/task_tests.doc")
      assert Recorder.pop_all() == %{errors: []}
    end

    test "run task with custom output and format" do
      mix_test_fun = fn opts ->
        assert opts == @mix_test_default_opts

        Recorder.add(%{
          RequestsGenerator.users_index()
          | endpoint: Tasks.Xcribe.DocTest.FakeEndpoint
        })
      end

      output =
        capture_io(fn ->
          Doc.run_task(
            ["--format", "api_blueprint", "--output", "/tmp/custom_output_task_test.doc"],
            mix_test_fun,
            FakeProjectNonUmbrella
          )
        end)

      assert output =~ "documentation written in /tmp/custom_output_task_test.doc"
      assert File.read!("/tmp/custom_output_task_test.doc") =~ "FORMAT: 1A"
      assert File.rm!("/tmp/custom_output_task_test.doc")
      assert Recorder.pop_all() == %{errors: []}
    end

    test "override path for umbrella apps" do
      mix_test_fun = fn opts ->
        assert opts == @mix_test_default_opts

        Recorder.add(%{
          RequestsGenerator.users_index()
          | endpoint: Tasks.Xcribe.DocTest.FakeEndpoint
        })
      end

      output = capture_io(fn -> Doc.run_task([], mix_test_fun, FakeProject) end)

      assert output =~ "documentation written in /tmp/fake_app/tmp/task_tests.doc"
      assert File.read!("/tmp/fake_app/tmp/task_tests.doc") =~ "securitySchemes"
      assert File.rm!("/tmp/fake_app/tmp/task_tests.doc")
      assert Recorder.pop_all() == %{errors: []}
    end

    test "generate docs for a specific endpoint" do
      mix_test_fun = fn opts ->
        assert opts == @mix_test_default_opts ++ ["/tmp/fake_app"]

        Recorder.add(%{
          RequestsGenerator.users_index()
          | endpoint: Tasks.Xcribe.DocTest.FakeEndpoint
        })
      end

      output =
        capture_io(fn ->
          Doc.run_task(
            ["--endpoint", "Tasks.Xcribe.DocTest.FakeEndpoint"],
            mix_test_fun,
            FakeProject
          )
        end)

      assert output =~ "documentation written in /tmp/fake_app/tmp/task_tests.doc"
      assert File.read!("/tmp/fake_app/tmp/task_tests.doc") =~ "securitySchemes"
      assert File.rm!("/tmp/fake_app/tmp/task_tests.doc")
      assert Recorder.pop_all() == %{errors: []}
    end

    test "send to test's task ignored options" do
      mix_test_fun = fn opts ->
        assert opts == @mix_test_default_opts ++ ["/custom/file/path", "--other", "value"]
      end

      output =
        capture_io(fn ->
          Doc.run_task(["/custom/file/path", "--other", "value"], mix_test_fun, FakeProject)
        end)

      assert output =~ "Xcribe Task - finished"
    end

    test "invalid endpoint module" do
      assert capture_io(fn ->
               Doc.run_task(["--endpoint", "InvalidEndpoint"])
             end) =~ "Couldn't find a path to endpoint InvalidEndpoint"
    catch
      :exit, message -> assert message == {:shutdown, 1}
    end

    test "when cant find otp_app path" do
      assert capture_io(fn ->
               Doc.run_task(
                 ["--endpoint", "Tasks.Xcribe.DocTest.FailFakeEndpoint"],
                 nil,
                 FakeProject
               )
             end) =~ "Couldn't find a path to endpoint InvalidEndpoint"
    catch
      :exit, message -> assert message == {:shutdown, 1}
    end

    test "invalid format option" do
      assert capture_io(fn ->
               Doc.run_task(["--format", "invalid"])
             end) =~ "Xcribe doesn't support the configured documentation format"
    catch
      :exit, message -> assert message == {:shutdown, 1}
    end
  end
end
