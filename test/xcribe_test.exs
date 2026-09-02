defmodule XcribeTest do
  use ExUnit.Case, async: true

  import ExUnit.CaptureIO

  alias Xcribe.{DocException, Request, Request.Error, SpecificationFile}

  alias Xcribe.Support.RequestsGenerator

  @sample_openapi_output File.read!("test/support/openapi_example.json")
  @sample_apib_output File.read!("test/support/api_blueprint_example.apib")

  test "README install version check" do
    app = :xcribe

    app_version = "#{Application.spec(app, :vsn)}"
    readme = File.read!("README.md")
    [_, readme_versions] = Regex.run(~r/{:#{app}, "(.+)"}/, readme)

    assert Version.match?(app_version, readme_versions)
  end

  describe "document/2" do
    @tag :tmp_dir
    test "write documentation with openapi format", %{tmp_dir: tmp_dir} do
      output_path = Path.join(tmp_dir, "openapi.json")

      records = [
        RequestsGenerator.users_index([:basic_auth]),
        RequestsGenerator.users_show([:basic_auth]),
        RequestsGenerator.users_create([:bearer_auth]),
        RequestsGenerator.users_update([:bearer_auth]),
        RequestsGenerator.users_delete([:bearer_auth]),
        RequestsGenerator.users_custom_action([:api_key_auth]),
        RequestsGenerator.users_posts_index([:api_key_auth]),
        RequestsGenerator.users_posts_create([:api_key_auth]),
        RequestsGenerator.users_posts_update([:api_key_auth])
      ]

      config = %{
        format: :openapi,
        specification_source: "test/support/.simple_example.exs",
        json_library: Jason,
        output: output_path
      }

      io_output =
        capture_io(fn ->
          assert Xcribe.document(records, config) == :ok
        end)

      assert io_output =~ "Xcribe documentation written in"

      assert output_path |> File.read!() |> Jason.decode!() ==
               Jason.decode!(@sample_openapi_output)
    end

    @tag :tmp_dir
    test "write documentation with api_blueprint format", %{tmp_dir: tmp_dir} do
      output_path = Path.join(tmp_dir, "api_doc.apib")

      records = [
        RequestsGenerator.users_index([:basic_auth]),
        RequestsGenerator.users_show([:basic_auth]),
        RequestsGenerator.users_create([:bearer_auth]),
        RequestsGenerator.users_update([:bearer_auth]),
        RequestsGenerator.users_delete([:bearer_auth]),
        RequestsGenerator.users_custom_action([:api_key_auth]),
        RequestsGenerator.users_posts_index([:api_key_auth]),
        RequestsGenerator.users_posts_create([:api_key_auth]),
        RequestsGenerator.users_posts_update([:api_key_auth])
      ]

      config = %{
        format: :api_blueprint,
        specification_source: "test/support/.simple_example.exs",
        json_library: Jason,
        output: output_path
      }

      io_output =
        capture_io(fn ->
          assert Xcribe.document(records, config) == :ok
        end)

      assert io_output =~ "Xcribe documentation written in"

      assert File.read!(output_path) == @sample_apib_output
    end

    @tag :tmp_dir
    test "handle an unreadable specification file", %{tmp_dir: tmp_dir} do
      spec_file = Path.join(tmp_dir, ".xcribe.exs")
      File.write!(spec_file, ~s(%{\n  "missing_comma" => 1\n  "missing_comma" => 2\n}\n))

      records = [RequestsGenerator.users_index()]

      config = %{
        format: :openapi,
        specification_source: spec_file,
        json_library: Jason,
        output: Path.join(tmp_dir, "openapi.json")
      }

      assert {:error, %SpecificationFile{message: message}} = Xcribe.document(records, config)
      assert message =~ "invalid Elixir syntax"
    end

    @tag :tmp_dir
    test "report a missing specification file instead of raising", %{tmp_dir: tmp_dir} do
      records = [RequestsGenerator.users_index()]

      config = %{
        format: :openapi,
        specification_source: ".not_there.exs",
        json_library: Jason,
        output: Path.join(tmp_dir, "openapi.json")
      }

      assert {:error, %SpecificationFile{message: message}} = Xcribe.document(records, config)
      assert message == "File not found .not_there.exs"
    end

    @tag :tmp_dir
    test "report an unwritable output file without crashing", %{tmp_dir: tmp_dir} do
      records = [RequestsGenerator.users_index()]

      config = %{
        format: :openapi,
        specification_source: "test/support/.simple_example.exs",
        json_library: Jason,
        output: tmp_dir
      }

      output = capture_io(fn -> assert Xcribe.document(records, config) == :error end)

      assert output =~ "Output file errors"
      assert output =~ "Could not write to #{tmp_dir}"
    end

    test "handle  validation errors" do
      invalid_request = %Request{
        request_body: %{date: ~D[2021-01-01]},
        __meta__: %{
          call: %{
            description: "test name",
            file: File.cwd!() <> "/test/xcribe_test.exs",
            line: 1
          }
        }
      }

      records = [invalid_request]

      assert capture_io(fn ->
               assert Xcribe.document(records, %{}) ==
                        {:error,
                         [
                           %Error{
                             __meta__: invalid_request.__meta__,
                             type: :validation,
                             message:
                               "The Plug.Conn params must be valid HTTP params. A struct Date was found!"
                           }
                         ]}
             end) == ""
    end

    test "handle multiple validation errors" do
      invalid_request = %Request{
        request_body: %{date: ~D[2021-01-01]},
        __meta__: %{
          call: %{
            description: "test name",
            file: File.cwd!() <> "/test/xcribe_test.exs",
            line: 1
          }
        }
      }

      valid_request = RequestsGenerator.users_index([:basic_auth])

      expected_error = %Error{
        __meta__: invalid_request.__meta__,
        type: :validation,
        message: "The Plug.Conn params must be valid HTTP params. A struct Date was found!"
      }

      records = [invalid_request, valid_request, invalid_request]

      assert capture_io(fn ->
               assert Xcribe.document(records, %{}) == {:error, [expected_error, expected_error]}
             end) == ""
    end

    test "handle document exceptions" do
      request_with_error = %{
        RequestsGenerator.users_index()
        | path_params: nil,
          __meta__: %{
            call: %{
              description: "conn test",
              file: File.cwd!() <> "/test/xcribe/cli/output_test.exs",
              line: 25
            }
          }
      }

      records = [request_with_error]

      config = %{
        format: :openapi,
        specification_source: "test/support/.simple_example.exs",
        json_library: Jason
      }

      assert capture_io(fn ->
               assert {:error, %DocException{}} = Xcribe.document(records, config)
             end) == ""
    end
  end
end
