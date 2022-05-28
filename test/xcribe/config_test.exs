defmodule Xcribe.ConfigTest do
  use ExUnit.Case, async: false

  alias Xcribe.Config

  setup do
    on_exit(fn ->
      :xcribe
      |> Application.get_all_env()
      |> Keyword.keys()
      |> Enum.each(&Application.delete_env(:xcribe, &1))

      System.delete_env("XCRIBE_ENV")
    end)
  end

  describe "active?/0" do
    test "return true when env var is 1" do
      System.put_env("XCRIBE_ENV", "1")
      assert Config.active?() == true
    end

    test "return true when env var is true" do
      System.put_env("XCRIBE_ENV", "1")
      assert Config.active?() == true
    end

    test "return true when env var is TRUE" do
      System.put_env("XCRIBE_ENV", "1")
      assert Config.active?() == true
    end

    test "return false when env var is an invalid value" do
      System.put_env("XCRIBE_ENV", "asdf")
      assert Config.active?() == false
    end

    test "return false when env var is not seted" do
      System.delete_env("XCRIBE_ENV")
      assert Config.active?() == false
    end
  end

  describe "all_endpoints/0" do
    test "return all configured endpoints" do
      Application.put_env(:xcribe, Xcribe.Endpoint, format: :api_blueprint)
      Application.put_env(:xcribe, NotValidEndpoint, format: :api_blueprint)

      assert Config.all_endpoints() == [Xcribe.Endpoint]
    end
  end

  describe "fetch_config/1" do
    test "fetch configuration with default values" do
      assert Config.fetch_config(Xcribe.FakeEndPoint) == %{
               format: :swagger,
               specification_source: ".xcribe.exs",
               json_library: Jason,
               output: "openapi.json",
               serve: false
             }
    end

    test "fetch configuration for endpoint" do
      Application.put_env(:xcribe, Xcribe.OtherEndpoint,
        format: :api_blueprint,
        specification_source: ".custom.file.exs",
        json_library: Jason,
        output: "api_doc.apib",
        serve: true
      )

      assert Config.fetch_config(Xcribe.OtherEndpoint) == %{
               format: :api_blueprint,
               specification_source: ".custom.file.exs",
               json_library: Jason,
               output: "api_doc.apib",
               serve: true
             }
    end
  end

  describe "check_configurations/2" do
    test "return ok if has valid configurations" do
      config = %{
        format: :swagger,
        specification_source: ".xcribe.exs",
        json_library: Jason,
        serve: false
      }

      assert Config.check_configurations(config) == {:ok, config}
    end

    test "validate serve config" do
      config = %{
        format: :swagger,
        specification_source: ".xcribe.exs",
        json_library: Jason,
        output: "priv/static/openapi.json",
        serve: true
      }

      assert Config.check_configurations(config, [:serve]) == {:ok, config}
    end

    test "return error for invalid configurations" do
      config = %{
        format: :invalid,
        specification_source: ".xcribe.exs",
        json_library: FakeJson,
        output: "",
        serve: true
      }

      assert Config.check_configurations(config) ==
               {:error,
                [
                  {:output, "",
                   "When serve config is true you must confiture output to \"priv/static\" folder",
                   "You must configure output as: `config :xcribe, Endpoint, output: \"priv/static/doc.json\"`"},
                  {:format, :invalid, "When serve config is true you must use swagger format",
                   "You must use Swagger format: `config :xcribe, Endpoint, format: :swagger`"},
                  {:json_library, FakeJson,
                   "The configured json library doesn't implement the needed functions",
                   "Try configure Xcribe with Jason or Poison `config :xcribe, Endpoint, json_library: Jason`"},
                  {:format, :invalid,
                   "Xcribe doesn't support the configured documentation format",
                   "Xcribe supports Swagger and Blueprint, configure as: `config :xcribe, Endpoint, format: :swagger`"}
                ]}
    end

    test "validate only given keys" do
      config = %{
        format: :invalid,
        specification_source: ".xcribe.exs",
        json_library: FakeJson,
        output: "",
        serve: true
      }

      assert Config.check_configurations(config, [:serve]) ==
               {:error,
                [
                  {:output, "",
                   "When serve config is true you must confiture output to \"priv/static\" folder",
                   "You must configure output as: `config :xcribe, Endpoint, output: \"priv/static/doc.json\"`"},
                  {:format, :invalid, "When serve config is true you must use swagger format",
                   "You must use Swagger format: `config :xcribe, Endpoint, format: :swagger`"}
                ]}
    end

    test "when specification file does not exists" do
      # TODO: implement
    end
  end
end
