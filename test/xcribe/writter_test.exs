defmodule Xcribe.WritterTest do
  use ExUnit.Case, async: true

  import ExUnit.CaptureIO

  alias Xcribe.Writter

  describe "write/2" do
    test "writes given text to set output directory" do
      output_path = "/tmp/xcribe_test#{:rand.uniform()}"

      config = %{output: output_path}

      assert capture_io(fn ->
               assert :ok == Writter.write("sample test", config)
             end) =~ "Xcribe documentation written in #{output_path}"

      assert File.read!(output_path) == "sample test"
    end

    test "raises InvalidOutputDestination if output directory cannot be accessed" do
      config = %{output: "/root/null"}

      assert capture_io(fn ->
               assert :error == Writter.write("sample test", config)
             end) =~ "Output file errors"
    end
  end
end
