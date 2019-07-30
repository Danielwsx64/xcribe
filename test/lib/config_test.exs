defmodule Xcribe.ConfigTest do
  use ExUnit.Case, async: false

  alias Xcribe.Config

  describe "output_file/0" do
    test "return the output file setuped at config" do
      Application.put_env(:xcribe, :output_file, "example.md")

      assert Config.output_file() == "example.md"
    end

    test "return default file name" do
      Application.delete_env(:xcribe, :output_file)

      assert Config.output_file() == "api_doc.apib"
    end
  end

  describe "active?/0" do
    test "return true when xcribe env var is defined" do
      Application.put_env(:xcribe, :env_var, "SHELL")

      assert Config.active?() == true
    end

    test "return false when xcribe env var is undefined" do
      Application.put_env(:xcribe, :env_var, "UNDEFINED_XCRIBE_ENV_VAR_!@#")

      assert Config.active?() == false
    end
  end
end
