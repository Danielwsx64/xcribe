defmodule Xcribe.ConfigTest do
  use ExUnit.Case, async: false

  alias Xcribe.Config

  @document_error_message "The documentation file to be served doesn't exist"
  @document_error_instructions "Generate the documentation before serving it: `mix xcribe.doc`"
  @serving_error_message "Your Endpoint must be able to serve the generated document, but a request for it didn't return the file"
  @serving_error_instructions ~s(Make file_path and file_name match a Plug.Static in your Endpoint — the directory it serves and its `only:` allow list: `config :xcribe, Endpoint, file_path: {"priv/static", "api"}, file_name: "openapi.json"`)

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
      System.put_env("XCRIBE_ENV", "true")
      assert Config.active?() == true
    end

    test "return true when env var is TRUE" do
      System.put_env("XCRIBE_ENV", "TRUE")
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

    test "return an empty list when no endpoint is configured" do
      :xcribe
      |> Application.get_all_env()
      |> Keyword.keys()
      |> Enum.each(&Application.delete_env(:xcribe, &1))

      assert Config.all_endpoints() == []
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
               serve: false,
               server_port: 4040,
               open_browser: false
             }
    end

    test "fetch the file name default of the api blueprint format" do
      Application.put_env(:xcribe, Xcribe.OtherEndpoint, format: :api_blueprint)

      assert Config.fetch_config(Xcribe.OtherEndpoint) == %{
               endpoint: Xcribe.OtherEndpoint,
               format: :api_blueprint,
               specification_source: ".xcribe.exs",
               json_library: Jason,
               file_path: nil,
               file_name: "api_doc.apib",
               serve: false,
               server_port: 4040,
               open_browser: false
             }
    end

    test "fetch configuration for endpoint" do
      Application.put_env(:xcribe, Xcribe.OtherEndpoint,
        format: :api_blueprint,
        specification_source: ".custom.file.exs",
        json_library: Jason,
        file_path: {"priv/static", "api"},
        file_name: "api_doc.apib",
        serve: true,
        server_port: 4321,
        open_browser: true
      )

      assert Config.fetch_config(Xcribe.OtherEndpoint) == %{
               endpoint: Xcribe.OtherEndpoint,
               format: :api_blueprint,
               specification_source: ".custom.file.exs",
               json_library: Jason,
               file_path: {"priv/static", "api"},
               file_name: "api_doc.apib",
               serve: true,
               server_port: 4321,
               open_browser: true
             }
    end

    test "accept the serve config as a string" do
      Application.put_env(:xcribe, Xcribe.OtherEndpoint, serve: "true")

      assert Config.fetch_config(Xcribe.OtherEndpoint).serve == true

      Application.put_env(:xcribe, Xcribe.OtherEndpoint, serve: "0")

      assert Config.fetch_config(Xcribe.OtherEndpoint).serve == false
    end

    test "accept the open browser config as a string" do
      Application.put_env(:xcribe, Xcribe.OtherEndpoint, open_browser: "true")

      assert Config.fetch_config(Xcribe.OtherEndpoint).open_browser == true

      Application.put_env(:xcribe, Xcribe.OtherEndpoint, open_browser: "1")

      assert Config.fetch_config(Xcribe.OtherEndpoint).open_browser == true

      Application.put_env(:xcribe, Xcribe.OtherEndpoint, open_browser: "0")

      assert Config.fetch_config(Xcribe.OtherEndpoint).open_browser == false
    end

    test "keep an unknown open browser value so it can be validated" do
      Application.put_env(:xcribe, Xcribe.OtherEndpoint, open_browser: "yes")

      assert Config.fetch_config(Xcribe.OtherEndpoint).open_browser == "yes"
    end
  end

  describe "serving_path/1" do
    test "return serving path when file_path is nil" do
      config = %{file_path: nil, file_name: "doc.json"}

      assert Config.serving_path(config) == "doc.json"
    end

    test "return serving path when file_path is a string" do
      config = %{file_path: "priv/static", file_name: "doc.json"}

      assert Config.serving_path(config) == "doc.json"
    end

    test "for subdirectories on the Plug.Static path, use a tuple" do
      config = %{file_path: {"priv/static", "api"}, file_name: "doc.json"}

      assert Config.serving_path(config) == "api/doc.json"
    end

    test "return only the file name when the tuple has no sub path" do
      config = %{file_path: {"priv/static", ""}, file_name: "doc.json"}

      assert Config.serving_path(config) == "doc.json"
    end

    test "drop a leading slash written in the sub path" do
      config = %{file_path: {"priv/static", "/api"}, file_name: "doc.json"}

      assert Config.serving_path(config) == "api/doc.json"
    end
  end

  describe "output_path/1" do
    test "return output path when file_path is nil" do
      config = %{file_path: nil, file_name: "doc.json"}

      assert Config.output_path(config) == "doc.json"
    end

    test "return output path when file_path is not given" do
      config = %{file_name: "doc.json"}

      assert Config.output_path(config) == "doc.json"
    end

    test "return output path when file_path is a string" do
      config = %{file_path: "priv/static", file_name: "doc.json"}

      assert Config.output_path(config) == "priv/static/doc.json"
    end

    test "for subdirectories on the Plug.Static path, use a tuple" do
      config = %{file_path: {"priv/static", "api"}, file_name: "doc.json"}

      assert Config.output_path(config) == "priv/static/api/doc.json"
    end

    test "return the static directory when the tuple has no sub path" do
      config = %{file_path: {"priv/static", ""}, file_name: "doc.json"}

      assert Config.output_path(config) == "priv/static/doc.json"
    end
  end

  describe "prefix_file_path/2" do
    test "prefix a file_path that is not configured" do
      config = %{file_path: nil, file_name: "doc.json"}

      assert Config.prefix_file_path(config, "/apps/api") == %{
               file_path: "/apps/api",
               file_name: "doc.json"
             }
    end

    test "prefix a file_path given as a string" do
      config = %{file_path: "priv/static", file_name: "doc.json"}

      assert Config.prefix_file_path(config, "/apps/api") == %{
               file_path: "/apps/api/priv/static",
               file_name: "doc.json"
             }
    end

    test "prefix only the static directory of a file_path tuple" do
      config = %{file_path: {"priv/static", "api"}, file_name: "doc.json"}

      assert Config.prefix_file_path(config, "/apps/api") == %{
               file_path: {"/apps/api/priv/static", "api"},
               file_name: "doc.json"
             }
    end
  end

  describe "check_configurations/2" do
    test "return ok if has valid configurations" do
      config = %{
        endpoint: Xcribe.StaticEndpoint,
        format: :openapi,
        specification_source: ".xcribe.exs",
        json_library: Jason,
        file_path: "test/support",
        file_name: "openapi_example.json",
        serve: false,
        server_port: 4040,
        open_browser: false
      }

      assert Config.check_configurations(config) == {:ok, config}
    end

    test "return error for invalid configurations" do
      config = %{
        endpoint: Xcribe.StaticEndpoint,
        format: :invalid,
        specification_source: ".invalid_one.exs",
        json_library: FakeJson,
        file_path: {"priv/static", :api},
        file_name: "",
        serve: true,
        server_port: 0,
        open_browser: "yes"
      }

      assert Config.check_configurations(config) ==
               {:error,
                [
                  {:format, :invalid,
                   "When serve config is true you must use the :openapi format",
                   "You must use the OpenAPI format: `config :xcribe, Endpoint, format: :openapi`"},
                  {:open_browser, "yes", "The configured open browser value is not a boolean",
                   "Configure open_browser as a boolean: `config :xcribe, Endpoint, open_browser: true`"},
                  {:server_port, 0, "The configured server port is not a port number",
                   "Configure a port between 1 and 65535: `config :xcribe, Endpoint, server_port: 4040`"},
                  {:file_name, "",
                   "The configured file name is not a name for the generated document",
                   "Configure the document file name: `config :xcribe, Endpoint, file_name: \"openapi.json\"`"},
                  {:file_path, {"priv/static", :api},
                   "The configured file path is not a directory nor a {static_dir, sub_path} tuple",
                   ~s(Configure a directory: `config :xcribe, Endpoint, file_path: "priv/static"`, or the two parts of a served path: `config :xcribe, Endpoint, file_path: {"priv/static", "api"}`)},
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
        endpoint: Xcribe.StaticEndpoint,
        format: :swagger,
        specification_source: ".xcribe.exs",
        json_library: Jason,
        file_path: "test/support",
        file_name: "openapi_example.json",
        serve: false,
        server_port: 4040,
        open_browser: false
      }

      assert Config.check_configurations(config) ==
               {:error,
                [
                  {:format, :swagger,
                   "Xcribe doesn't support the configured documentation format",
                   "Xcribe supports :openapi and :api_blueprint, configure as: `config :xcribe, Endpoint, format: :openapi`. The :swagger format was renamed to :openapi."}
                ]}
    end

    test "accept a json library that was not loaded yet" do
      config = %{
        endpoint: Xcribe.StaticEndpoint,
        format: :openapi,
        specification_source: ".xcribe.exs",
        json_library: Jason,
        file_path: "test/support",
        file_name: "openapi_example.json",
        serve: false,
        server_port: 4040,
        open_browser: false
      }

      :code.purge(Jason)
      :code.delete(Jason)

      assert Config.check_configurations(config, [:json_library]) == {:ok, config}
    end

    test "return error for an invalid file path" do
      config = %{
        endpoint: Xcribe.StaticEndpoint,
        format: :openapi,
        specification_source: ".xcribe.exs",
        json_library: Jason,
        file_path: {"priv/static", :api},
        file_name: "openapi_example.json",
        serve: false,
        server_port: 4040,
        open_browser: false
      }

      assert Config.check_configurations(config, [:file_path]) ==
               {:error,
                [
                  {:file_path, {"priv/static", :api},
                   "The configured file path is not a directory nor a {static_dir, sub_path} tuple",
                   ~s(Configure a directory: `config :xcribe, Endpoint, file_path: "priv/static"`, or the two parts of a served path: `config :xcribe, Endpoint, file_path: {"priv/static", "api"}`)}
                ]}
    end

    test "accept every supported file path shape" do
      for file_path <- [nil, "priv/static", {"priv/static", "api"}] do
        config = %{
          endpoint: Xcribe.StaticEndpoint,
          format: :openapi,
          specification_source: ".xcribe.exs",
          json_library: Jason,
          file_path: file_path,
          file_name: "openapi_example.json",
          serve: false,
          server_port: 4040,
          open_browser: false
        }

        assert Config.check_configurations(config, [:file_path]) == {:ok, config}
      end
    end

    test "return error for an invalid server port" do
      config = %{
        endpoint: Xcribe.StaticEndpoint,
        format: :openapi,
        specification_source: ".xcribe.exs",
        json_library: Jason,
        file_path: "test/support",
        file_name: "openapi_example.json",
        serve: false,
        server_port: "4040",
        open_browser: false
      }

      assert Config.check_configurations(config, [:server_port]) ==
               {:error,
                [
                  {:server_port, "4040", "The configured server port is not a port number",
                   "Configure a port between 1 and 65535: `config :xcribe, Endpoint, server_port: 4040`"}
                ]}
    end

    test "validate only given keys" do
      config = %{
        endpoint: Xcribe.StaticEndpoint,
        format: :invalid,
        specification_source: ".xcribe.exs",
        json_library: FakeJson,
        file_path: "test/support",
        file_name: "",
        serve: true,
        server_port: 4040,
        open_browser: false
      }

      assert Config.check_configurations(config, [:serve]) ==
               {:error,
                [
                  {:format, :invalid,
                   "When serve config is true you must use the :openapi format",
                   "You must use the OpenAPI format: `config :xcribe, Endpoint, format: :openapi`"}
                ]}
    end

    test "skip the serve validations when serve is false" do
      config = %{
        endpoint: Xcribe.StaticEndpoint,
        format: :api_blueprint,
        specification_source: ".xcribe.exs",
        json_library: Jason,
        file_path: "test/support",
        file_name: "openapi_example.json",
        serve: false,
        server_port: 4040,
        open_browser: false
      }

      assert Config.check_configurations(config, [:serve]) == {:ok, config}
    end

    test "return error for an invalid serve value" do
      config = %{
        endpoint: Xcribe.StaticEndpoint,
        format: :openapi,
        specification_source: ".xcribe.exs",
        json_library: Jason,
        file_path: "test/support",
        file_name: "openapi_example.json",
        serve: "yes",
        server_port: 4040,
        open_browser: false
      }

      assert Config.check_configurations(config, [:serve]) ==
               {:error,
                [
                  {:serve, "yes", "The configured serve value is not a boolean",
                   "Configure serve as a boolean: `config :xcribe, Endpoint, serve: true`"}
                ]}
    end

    test "return error for an invalid file name" do
      config = %{
        endpoint: Xcribe.StaticEndpoint,
        format: :openapi,
        specification_source: ".xcribe.exs",
        json_library: Jason,
        file_path: "test/support",
        file_name: nil,
        serve: false,
        server_port: 4040,
        open_browser: false
      }

      assert Config.check_configurations(config, [:file_name]) ==
               {:error,
                [
                  {:file_name, nil,
                   "The configured file name is not a name for the generated document",
                   "Configure the document file name: `config :xcribe, Endpoint, file_name: \"openapi.json\"`"}
                ]}
    end
  end

  describe "check_configurations/2 with the served_document key" do
    test "return ok when the endpoint serves the generated document" do
      config = %{
        endpoint: Xcribe.StaticEndpoint,
        format: :openapi,
        specification_source: ".xcribe.exs",
        json_library: Jason,
        file_path: "test/support",
        file_name: "openapi_example.json",
        serve: true,
        server_port: 4040,
        open_browser: false
      }

      assert Config.check_configurations(config, [:served_document]) == {:ok, config}
    end

    test "skip the validation when serve is false" do
      config = %{
        endpoint: Xcribe.StaticEndpoint,
        format: :openapi,
        specification_source: ".xcribe.exs",
        json_library: Jason,
        file_path: "not/a/directory",
        file_name: "openapi_example.json",
        serve: false,
        server_port: 4040,
        open_browser: false
      }

      assert Config.check_configurations(config, [:served_document]) == {:ok, config}
    end

    @tag :tmp_dir
    test "return error when the document was not generated yet", %{tmp_dir: tmp_dir} do
      config = %{
        endpoint: Xcribe.StaticEndpoint,
        format: :openapi,
        specification_source: ".xcribe.exs",
        json_library: Jason,
        file_path: tmp_dir,
        file_name: "openapi.json",
        serve: true,
        server_port: 4040,
        open_browser: false
      }

      assert Config.check_configurations(config, [:served_document]) ==
               {:error,
                [
                  {:file_path, Path.join(tmp_dir, "openapi.json"), @document_error_message,
                   @document_error_instructions}
                ]}
    end

    @tag :tmp_dir
    test "do not create the document while validating", %{tmp_dir: tmp_dir} do
      config = %{
        endpoint: Xcribe.StaticEndpoint,
        format: :openapi,
        specification_source: ".xcribe.exs",
        json_library: Jason,
        file_path: tmp_dir,
        file_name: "openapi.json",
        serve: true,
        server_port: 4040,
        open_browser: false
      }

      assert {:error, _errors} = Config.check_configurations(config, [:served_document])

      refute File.exists?(Path.join(tmp_dir, "openapi.json"))
    end

    test "return error when the endpoint doesn't serve the document path" do
      config = %{
        endpoint: Xcribe.Endpoint,
        format: :openapi,
        specification_source: ".xcribe.exs",
        json_library: Jason,
        file_path: "test/support",
        file_name: "openapi_example.json",
        serve: true,
        server_port: 4040,
        open_browser: false
      }

      assert Config.check_configurations(config, [:served_document]) ==
               {:error,
                [
                  {:file_path, "openapi_example.json", @serving_error_message,
                   @serving_error_instructions}
                ]}
    end

    test "return error when the document is out of the Plug.Static allow list" do
      config = %{
        endpoint: Xcribe.StaticEndpoint,
        format: :openapi,
        specification_source: ".xcribe.exs",
        json_library: Jason,
        file_path: "test/support",
        file_name: "api_blueprint_example.apib",
        serve: true,
        server_port: 4040,
        open_browser: false
      }

      assert Config.check_configurations(config, [:served_document]) ==
               {:error,
                [
                  {:file_path, "api_blueprint_example.apib", @serving_error_message,
                   @serving_error_instructions}
                ]}
    end

    test "return error when the endpoint module can't be called" do
      config = %{
        endpoint: Xcribe.NotAnEndpoint,
        format: :openapi,
        specification_source: ".xcribe.exs",
        json_library: Jason,
        file_path: "test/support",
        file_name: "openapi_example.json",
        serve: true,
        server_port: 4040,
        open_browser: false
      }

      assert Config.check_configurations(config, [:served_document]) ==
               {:error,
                [
                  {:file_path, "openapi_example.json", @serving_error_message,
                   @serving_error_instructions}
                ]}
    end
  end
end
