defmodule Xcribe.Tasks.GenSpecTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  alias Mix.Tasks.Xcribe.Gen.Spec
  alias Xcribe.Specification

  describe "run/1" do
    @tag :tmp_dir
    test "create the specification file", %{tmp_dir: tmp_dir} do
      file = Path.join(tmp_dir, ".xcribe.exs")

      output = capture_io(fn -> Spec.run(["--output", file]) end)

      assert output =~ "Xcribe specification file written in #{file}"
      assert File.exists?(file)
    end

    @tag :tmp_dir
    test "accept the short output alias", %{tmp_dir: tmp_dir} do
      file = Path.join(tmp_dir, "api_spec.exs")

      capture_io(fn -> Spec.run(["-o", file]) end)

      assert File.exists?(file)
    end

    @tag :tmp_dir
    test "never overwrite an existing file, and fail", %{tmp_dir: tmp_dir} do
      file = Path.join(tmp_dir, ".xcribe.exs")
      File.write!(file, "%{name: \"Untouched\"}\n")

      output =
        capture_io(fn ->
          assert catch_exit(Spec.run(["--output", file])) == {:shutdown, 1}
        end)

      assert output =~ "already exists"
      assert File.read!(file) == "%{name: \"Untouched\"}\n"
    end

    @tag :tmp_dir
    test "the generated file is read back unchanged", %{tmp_dir: tmp_dir} do
      file = Path.join(tmp_dir, ".xcribe.exs")

      capture_io(fn -> Spec.run(["--output", file]) end)

      assert Specification.api_specification(%{specification_source: file}) ==
               Specification.defaults()
    end
  end
end
