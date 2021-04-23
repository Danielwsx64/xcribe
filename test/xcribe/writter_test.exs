defmodule Xcribe.WritterTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  alias Xcribe.Writter

  setup do
    on_exit(fn ->
      Application.delete_env(:xcribe, :output)
    end)

    :ok
  end

  describe "write/1" do
    test "writes given text to set output directory" do
      output_path = "/tmp/xcribe_#{:rand.uniform()}"
      Application.put_env(:xcribe, :output, output_path)

      assert capture_io(fn ->
               assert :ok == Writter.write("sample test")
             end) =~ "Xcribe documentation written in #{output_path}"

      assert File.read!(output_path) == "sample test"
    end

    test "raises InvalidOutputDestination if output directory cannot be accessed" do
      invalid_output_path = "/root/null"
      Application.put_env(:xcribe, :output, invalid_output_path)

      assert capture_io(fn ->
               assert :error == Writter.write("sample test")
             end) =~ "Output file errors"
    end
  end
end
