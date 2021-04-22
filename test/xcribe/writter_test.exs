defmodule Xcribe.WritterTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  alias Xcribe.Writter

  @output_path "/tmp/test"
  @invalid_output_path "/root/null"

  describe "write/1" do
    test "writes given text to set output directory" do
      Application.put_env(:xcribe, :output, @output_path)

      assert capture_io(fn ->
               assert :ok == Writter.write("sample test")
             end) =~ "Xcribe documentation written in #{@output_path}"
    end

    test "raises InvalidOutputDestination if output directory cannot be accessed" do
      Application.put_env(:xcribe, :output, @invalid_output_path)

      assert capture_io(fn ->
        assert :error == Writter.write("sample test")
      end) =~ "Output file errors"
    end
  end
end
