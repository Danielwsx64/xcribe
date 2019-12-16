defmodule Xcribe.ConfigTest do
  use ExUnit.Case, async: false

  alias Xcribe.Config

  describe "output_file/0" do
    test "return the output file setuped at config" do
      Application.put_env(:xcribe, :output_file, "example.md")

      assert Config.output_file() == "example.md"
    end

    test "return default file name for ApiBlueprint" do
      Application.put_env(:xcribe, :doc_format, :api_blueprint)
      Application.delete_env(:xcribe, :output_file)

      assert Config.output_file() == "api_doc.apib"
    end

    test "return default file name for Swagger" do
      Application.put_env(:xcribe, :doc_format, :swagger)
      Application.delete_env(:xcribe, :output_file)

      assert Config.output_file() == "openapi.json"
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

  describe "doc_format/0" do
    test "when ApiBlueprint format is specified" do
      Application.put_env(:xcribe, :doc_format, :api_blueprint)

      assert Config.doc_format() == :api_blueprint
    end

    test "when Swagger format is specified" do
      Application.put_env(:xcribe, :doc_format, :swagger)

      assert Config.doc_format() == :swagger
    end

    test "when an invalid format is specified" do
      Application.put_env(:xcribe, :doc_format, :invalid)

      assert Config.doc_format() == :error
    end
  end
end
