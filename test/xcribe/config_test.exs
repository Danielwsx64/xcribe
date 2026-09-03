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
      :xcribe
      |> Application.get_all_env()
      |> Keyword.keys()
      |> Enum.each(&Application.delete_env(:xcribe, &1))

      Application.put_all_env(
        xcribe: [
          {Xcribe.Endpoint, format: :api_blueprint},
          {NotValidEndpoint, format: :api_blueprint}
        ]
      )

      assert Config.all_endpoints() == [Xcribe.Endpoint]
    end
  end

  describe "fetch_config/1" do
    test "fetch configuration with default values" do
      assert Config.fetch_config(Xcribe.FakeEndPoint) == %{
               endpoint: Xcribe.FakeEndPoint,
               format: :openapi,
               specification_source: ".xcribe.exs",
               json_library: Jason,
               file_path: nil,
               file_name: "openapi.json",
               serve: false
             }
    end

    test "fetch configuration for endpoint" do
      Application.put_env(:xcribe, Xcribe.OtherEndpoint,
        format: :api_blueprint,
        specification_source: ".custom.file.exs",
        json_library: Jason,
        file_name: "api_doc.apib",
        serve: true
      )

      assert Config.fetch_config(Xcribe.OtherEndpoint) == %{
               endpoint: Xcribe.OtherEndpoint,
               format: :api_blueprint,
               specification_source: ".custom.file.exs",
               json_library: Jason,
               file_path: nil,
               file_name: "api_doc.apib",
               serve: true
             }
    end
  end

  describe "get_serving_path/1" do
    test "return serving path when file_path is nil" do
      config = %{file_path: nil, file_name: "doc.json"}

      assert Config.get_serving_path(config) == "doc.json"
    end

    test "return serving path when file_path is a string" do
      config = %{file_path: "priv/static", file_name: "doc.json"}

      assert Config.get_serving_path(config) == "doc.json"
    end

    test "for subdirectories on the Plug.Static path, use a tuple" do
      config = %{file_path: {"priv/static", "api"}, file_name: "doc.json"}

      assert Config.get_serving_path(config) == "api/doc.json"
    end
  end

  describe "get_output_path/1" do
    test "return serving path when file_path is nil" do
      config = %{file_path: nil, file_name: "doc.json"}

      assert Config.get_output_path(config) == "doc.json"
    end

    test "return serving path when file_path is a string" do
      config = %{file_path: "priv/static", file_name: "doc.json"}

      assert Config.get_output_path(config) == "priv/static/doc.json"
    end

    test "for subdirectories on the Plug.Static path, use a tuple" do
      config = %{file_path: {"priv/static", "api"}, file_name: "doc.json"}

      assert Config.get_output_path(config) == "priv/static/api/doc.json"
    end
  end

  describe "check_configurations/2" do
    test "return ok if has valid configurations" do
      config = %{
        format: :openapi,
        specification_source: ".xcribe.exs",
        json_library: Jason,
        serve: false
      }

      assert Config.check_configurations(config) == {:ok, config}
    end

    @tag :tmp_dir
    test "validate serve config", %{tmp_dir: tmp_dir} do
      config = %{
        endpoint: Xcribe.Support.StaticEndpoint,
        format: :openapi,
        specification_source: ".xcribe.exs",
        json_library: Jason,
        file_path: tmp_dir,
        file_name: "openapi_example.json",
        serve: true
      }

      assert Config.check_configurations(config, [:serve]) == {:ok, config}
    end

    test "return error for invalid configurations" do
      config = %{
        endpoint: Xcribe.Endpoint,
        format: :invalid,
        specification_source: ".invalid_one.exs",
        json_library: FakeJson,
        file_name: "",
        serve: true
      }

      assert Config.check_configurations(config) ==
               {:error,
                [
                  {:file_path, "",
                   "When serve config is true your Endpoint must be able to serve the generated document, but a request for it didn't return the file",
                   "Make file_path and file_name match a Plug.Static in your Endpoint — the directory it serves and its `only:` allow list: `config :xcribe, Endpoint, file_path: {\"priv/static\", \"api\"}, file_name: \"openapi.json\"`"},
                  {:format, :invalid,
                   "When serve config is true you must use the :openapi format",
                   "You must use the OpenAPI format: `config :xcribe, Endpoint, format: :openapi`"},
                  {:json_library, FakeJson,
                   "The configured json library doesn't implement the needed functions",
                   "Try configure Xcribe with Jason or Poison `config :xcribe, Endpoint, json_library: Jason`"},
                  {:specification_source, ".invalid_one.exs",
                   "The configured specification file doesn't exist",
                   "Add a valid spec file path in `config :xcribe, Endpoint, specification_source: \".xcribe.exs\"`"},
                  {:format, :invalid,
                   "Xcribe doesn't support the configured documentation format",
                   "Xcribe supports :openapi and :api_blueprint, configure as: `config :xcribe, Endpoint, format: :openapi`. The :swagger format was renamed to :openapi."}
                ]}
    end

    test "reject the removed swagger format" do
      config = %{
        format: :swagger,
        specification_source: ".xcribe.exs",
        json_library: Jason,
        file_name: "openapi.json",
        serve: false
      }

      assert Config.check_configurations(config) ==
               {:error,
                [
                  {:format, :swagger,
                   "Xcribe doesn't support the configured documentation format",
                   "Xcribe supports :openapi and :api_blueprint, configure as: `config :xcribe, Endpoint, format: :openapi`. The :swagger format was renamed to :openapi."}
                ]}
    end

    test "validate only given keys" do
      config = %{
        endpoint: Xcribe.Endpoint,
        format: :invalid,
        specification_source: ".xcribe.exs",
        json_library: FakeJson,
        file_name: "",
        serve: true
      }

      assert Config.check_configurations(config, [:serve]) ==
               {:error,
                [
                  {:file_path, "",
                   "When serve config is true your Endpoint must be able to serve the generated document, but a request for it didn't return the file",
                   "Make file_path and file_name match a Plug.Static in your Endpoint — the directory it serves and its `only:` allow list: `config :xcribe, Endpoint, file_path: {\"priv/static\", \"api\"}, file_name: \"openapi.json\"`"},
                  {:format, :invalid,
                   "When serve config is true you must use the :openapi format",
                   "You must use the OpenAPI format: `config :xcribe, Endpoint, format: :openapi`"}
                ]}
    end

    test "validate the Plug.Static configuration for the doc" do
      config = %{
        endpoint: Xcribe.Support.StaticEndpoint,
        format: :openapi,
        json_library: FakeJson,
        file_path: "test/support/",
        file_name: "openapi_example.json",
        serve: true
      }

      wrong_path = %{config | file_path: {"priv/static", "api"}}
      other_endpoint = %{config | endpoint: Xcribe.Endpoint}

      assert Config.check_configurations(config, [:serve]) == {:ok, config}

      assert Config.check_configurations(wrong_path, [:serve]) ==
               {:error,
                [
                  {:file_path, "api/openapi_example.json",
                   "When serve config is true your Endpoint must be able to serve the generated document, but a request for it didn't return the file",
                   "Make file_path and file_name match a Plug.Static in your Endpoint — the directory it serves and its `only:` allow list: `config :xcribe, Endpoint, file_path: {\"priv/static\", \"api\"}, file_name: \"openapi.json\"`"}
                ]}

      assert Config.check_configurations(other_endpoint, [:serve]) ==
               {:error,
                [
                  {:file_path, "openapi_example.json",
                   "When serve config is true your Endpoint must be able to serve the generated document, but a request for it didn't return the file",
                   "Make file_path and file_name match a Plug.Static in your Endpoint — the directory it serves and its `only:` allow list: `config :xcribe, Endpoint, file_path: {\"priv/static\", \"api\"}, file_name: \"openapi.json\"`"}
                ]}
    end
  end
end
