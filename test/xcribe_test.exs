defmodule XcribeTest do
  use ExUnit.Case, async: true

  import ExUnit.CaptureIO

  alias Xcribe.{DocException, Request, Request.Error}

  alias Xcribe.Support.RequestsGenerator

  @sample_swagger_output File.read!("test/support/swagger_example.json")
  @sample_apib_output File.read!("test/support/api_blueprint_example.apib")

  test "README install version check" do
    app = :xcribe

    app_version = "#{Application.spec(app, :vsn)}"
    readme = File.read!("README.md")
    [_, readme_versions] = Regex.run(~r/{:#{app}, "(.+)"}/, readme)

    assert Version.match?(app_version, readme_versions)
  end

  describe "document/2" do
    test "write documentation with swagger format" do
      output_path = "/tmp/xcribe_test_#{:rand.uniform()}"

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
        format: :swagger,
        specification_source: "test/support/.simple_example.exs",
        json_library: Jason,
        output: output_path
      }

      expected_content = String.replace(@sample_swagger_output, ~r/\s/, "")

      io_output =
        capture_io(fn ->
          assert Xcribe.document(records, config) == :ok
        end)

      assert io_output =~ "Xcribe documentation written in"

      assert output_path |> File.read!() |> String.replace(~r/\s/, "") == expected_content
    end

    test "write documentation with api_blueprint format" do
      output_path = "/tmp/xcribe_test_#{:rand.uniform()}"

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
      request_with_error = %Request{
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
        format: :swagger,
        specification_source: "test/support/.simple_example.exs",
        json_library: Jason
      }

      assert capture_io(fn ->
               assert {:error, %DocException{}} = Xcribe.document(records, config)
             end) == ""
    end
  end
end
