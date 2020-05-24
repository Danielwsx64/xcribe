defmodule Xcribe.ConfigTest do
  use ExUnit.Case, async: false

  alias Xcribe.Config
  alias Xcribe.{MissingInformationSource, UnknownFormat}

  setup do
    on_exit(fn ->
      # Current config keys
      Application.delete_env(:xcribe, :output)
      Application.delete_env(:xcribe, :env_var)
      Application.delete_env(:xcribe, :format)
      Application.delete_env(:xcribe, :json_library)
      Application.delete_env(:xcribe, :information_source)

      # Deprecated config keys
      Application.delete_env(:xcribe, :output_file)
      Application.delete_env(:xcribe, :doc_format)
    end)

    :ok
  end

  describe "output_file/0" do
    test "return configured output name" do
      Application.put_env(:xcribe, :output, "example.md")
      assert Config.output_file() == "example.md"
    end

    test "return default file name for ApiBlueprint" do
      Application.put_env(:xcribe, :format, :api_blueprint)
      assert Config.output_file() == "api_doc.apib"
    end

    test "return default file name for Swagger" do
      Application.put_env(:xcribe, :format, :swagger)
      assert Config.output_file() == "openapi.json"
    end

    test "deprecated configuration" do
      # return the output file setted at config
      Application.put_env(:xcribe, :output_file, "example.md")
      assert Config.output_file() == "example.md"
      Application.delete_env(:xcribe, :output_file)

      # return default file name for ApiBlueprint
      Application.delete_env(:xcribe, :format)
      Application.put_env(:xcribe, :doc_format, :api_blueprint)
      assert Config.output_file() == "api_doc.apib"
      Application.delete_env(:xcribe, :doc_format)

      # return default file name for Swagger
      Application.put_env(:xcribe, :doc_format, :swagger)
      assert Config.output_file() == "openapi.json"
    end
  end

  describe "active?/0" do
    test "return true when xcribe env var is defined" do
      Application.put_env(:xcribe, :env_var, "EXISTING_ENV_VAR_NEW_CONFIG")
      System.put_env("EXISTING_ENV_VAR_NEW_CONFIG", "1")

      assert Config.active?() == true
    end

    test "return false when xcribe env var is undefined" do
      Application.put_env(:xcribe, :env_var, "UNDEFINED_XCRIBE_ENV_VAR_!@#")

      assert Config.active?() == false
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
    end
  end

  describe "doc_format!/0" do
    test "when ApiBlueprint format is specified" do
      Application.put_env(:xcribe, :format, :api_blueprint)

      assert Config.doc_format!() == :api_blueprint
    end

    test "when an invalid format is specified" do
      Application.put_env(:xcribe, :format, :invalid)

      assert_raise UnknownFormat, fn ->
        Config.doc_format!()
      end
    end

    test "depecated config invalid" do
      # when an invalid format is specified
      Application.delete_env(:xcribe, :format)
      Application.put_env(:xcribe, :doc_format, :invalid)

      assert_raise UnknownFormat, fn ->
        Config.doc_format!()
      end
    end
  end

  describe "doc_format/0" do
    test "when ApiBlueprint format is specified" do
      Application.put_env(:xcribe, :format, :api_blueprint)

      assert Config.doc_format() == :api_blueprint
    end

    test "when Swagger format is specified" do
      Application.put_env(:xcribe, :format, :swagger)

      assert Config.doc_format() == :swagger
    end

    test "deprecated configuration" do
      # when ApiBlueprint format is specified
      Application.put_env(:xcribe, :doc_format, :api_blueprint)
      assert Config.doc_format() == :api_blueprint

      # when Swagger format is specified
      Application.put_env(:xcribe, :doc_format, :swagger)
      assert Config.doc_format() == :swagger
    end
  end

  describe "xcribe_information_source!/0" do
    test "return information source" do
      Application.put_env(:xcribe, :information_source, FakeOne)
      assert Config.xcribe_information_source!() == FakeOne
    end

    test "when module is not configured" do
      Application.delete_env(:xcribe, :information_source)

      assert_raise MissingInformationSource, fn ->
        Config.xcribe_information_source!()
      end
    end
  end

  describe "xcribe_information_source/0" do
    test "return information source" do
      Application.put_env(:xcribe, :information_source, FakeOne)
      assert Config.xcribe_information_source() == FakeOne
    end

    test "deprecated configuration" do
      # return information source
      Application.put_env(:xcribe, :information_source, FakeOne)
      assert Config.xcribe_information_source() == FakeOne
    end
  end

  describe "json_library/o" do
    test "return configured json library" do
      Application.put_env(:xcribe, :json_library, FakeOne)
      assert Config.json_library() == FakeOne
    end

    test "return Phoenix configured json library" do
      assert Config.json_library() == Jason
    end
  end

  describe "check_configurations/0" do
    test "return ok if has valid configurations" do
      Application.put_env(:xcribe, :json_library, Jason)
      Application.put_env(:xcribe, :information_source, Xcribe.Support.Information)
      Application.put_env(:xcribe, :format, :swagger)

      assert Config.check_configurations() == :ok
    end

    test "return error for invalid configurations" do
      Application.put_env(:xcribe, :json_library, FakeJson)
      Application.put_env(:xcribe, :information_source, FakeInfo)
      Application.put_env(:xcribe, :format, :invalid)

      assert Config.check_configurations() ==
               {:error,
                [
                  {:json_library, FakeJson,
                   "Given json library doesn't implement needed functions",
                   "Try configure Xcribe with Jason or Poison `config :xcribe, [json_library: Jason]`"},
                  {:information_source, FakeInfo,
                   "Sees like the given module is not using Xcribe as :information",
                   "Add `use Xcribe, :information` on top of your module"},
                  {:format, :invalid, "An not supported format was configured",
                   "Xcribe supports Swagger and Blueprint, configure as: `config :xcribe, [format: :swagger]`"}
                ]}
    end
  end
end
