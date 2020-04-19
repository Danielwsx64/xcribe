defmodule Xcribe.ConfigTest do
  use ExUnit.Case, async: false

  alias Xcribe.Config
  alias Xcribe.{MissingInformationSource, UnknownFormat}

  describe "output_file/0" do
    test "return configured output name" do
      Application.put_env(:xcribe, :configuration, output: "example.md")
      assert Config.output_file() == "example.md"
      Application.delete_env(:xcribe, :configuration)
    end

    test "return default file name for ApiBlueprint" do
      Application.put_env(:xcribe, :configuration, format: :api_blueprint)
      assert Config.output_file() == "api_doc.apib"
      Application.delete_env(:xcribe, :configuration)
    end

    test "return default file name for Swagger" do
      Application.put_env(:xcribe, :configuration, format: :swagger)
      assert Config.output_file() == "openapi.json"
      Application.delete_env(:xcribe, :configuration)
    end

    test "deprecated configuration" do
      # return the output file setted at config
      Application.put_env(:xcribe, :output_file, "example.md")
      assert Config.output_file() == "example.md"
      Application.delete_env(:xcribe, :output_file)

      # return default file name for ApiBlueprint
      Application.put_env(:xcribe, :doc_format, :api_blueprint)
      assert Config.output_file() == "api_doc.apib"
      Application.delete_env(:xcribe, :doc_format)

      # return default file name for Swagger
      Application.put_env(:xcribe, :doc_format, :swagger)
      assert Config.output_file() == "openapi.json"
      Application.delete_env(:xcribe, :doc_format)
    end
  end

  describe "active?/0" do
    test "return true when xcribe env var is defined" do
      Application.put_env(:xcribe, :configuration, env_var: "EXISTING_ENV_VAR_NEW_CONFIG")
      System.put_env("EXISTING_ENV_VAR_NEW_CONFIG", "1")

      assert Config.active?() == true
      Application.delete_env(:xcribe, :configuration)
    end

    test "return false when xcribe env var is undefined" do
      Application.put_env(:xcribe, :configuration, env_var: "UNDEFINED_XCRIBE_ENV_VAR_!@#")

      assert Config.active?() == false
      Application.delete_env(:xcribe, :configuration)
    end

    test "return true for default env var name" do
      System.put_env("XCRIBE_ENV", "1")

      assert Config.active?() == true
    end

    test "deprecated configuration" do
      # return true when xcribe env var is defined
      Application.put_env(:xcribe, :env_var, "EXISTING_ENV_VAR")
      System.put_env("EXISTING_ENV_VAR", "1")
      assert Config.active?() == true

      # return false when xcribe env var is undefined
      Application.put_env(:xcribe, :env_var, "UNDEFINED_XCRIBE_ENV_VAR_!@#")
      assert Config.active?() == false
      Application.delete_env(:xcribe, :env_var)
    end
  end

  describe "doc_format/0" do
    test "when ApiBlueprint format is specified" do
      Application.put_env(:xcribe, :configuration, format: :api_blueprint)

      assert Config.doc_format() == :api_blueprint
      Application.delete_env(:xcribe, :configuration)
    end

    test "when Swagger format is specified" do
      Application.put_env(:xcribe, :configuration, format: :swagger)

      assert Config.doc_format() == :swagger
      Application.delete_env(:xcribe, :configuration)
    end

    test "when an invalid format is specified" do
      Application.put_env(:xcribe, :configuration, format: :invalid)

      assert_raise UnknownFormat, fn ->
        Config.doc_format()
      end

      Application.delete_env(:xcribe, :configuration)
    end

    test "deprecated configuration" do
      # when ApiBlueprint format is specified
      Application.put_env(:xcribe, :doc_format, :api_blueprint)
      assert Config.doc_format() == :api_blueprint
      Application.delete_env(:xcribe, :doc_format)

      # when Swagger format is specified
      Application.put_env(:xcribe, :doc_format, :swagger)
      assert Config.doc_format() == :swagger
      Application.delete_env(:xcribe, :doc_format)

      # when an invalid format is specified
      Application.put_env(:xcribe, :doc_format, :invalid)

      assert_raise UnknownFormat, fn ->
        Config.doc_format()
      end

      Application.delete_env(:xcribe, :doc_format)
    end
  end

  describe "xcribe_information_source/0" do
    test "return information source" do
      Application.put_env(:xcribe, :configuration, information_source: FakeOne)
      assert Config.xcribe_information_source() == FakeOne
      Application.delete_env(:xcribe, :configuration)
    end

    test "when module is not configured" do
      assert_raise MissingInformationSource, fn ->
        Config.xcribe_information_source()
      end
    end

    test "deprecated configuration" do
      # return information source
      Application.put_env(:xcribe, :information_source, FakeOne)
      assert Config.xcribe_information_source() == FakeOne
      Application.delete_env(:xcribe, :information_source)
    end
  end

  describe "json_library/o" do
    test "return configured json library" do
      Application.put_env(:xcribe, :configuration, json_library: FakeOne)
      assert Config.json_library() == FakeOne
      Application.delete_env(:xcribe, :configuration)
    end

    test "return Phoenix configured json library" do
      assert Config.json_library() == Jason
    end
  end
end
