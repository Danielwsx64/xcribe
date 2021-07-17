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

  describe "generate_doc/2" do
    test "write documentation with swagger format" do
      output_path = "/tmp/xcribe_test_#{:rand.uniform()}"

      recorded = %{
        records: [
          RequestsGenerator.users_index([:basic_auth]),
          RequestsGenerator.users_show([:basic_auth]),
          RequestsGenerator.users_create([:bearer_auth]),
          RequestsGenerator.users_update([:bearer_auth]),
          RequestsGenerator.users_delete([:bearer_auth]),
          RequestsGenerator.users_custom_action([:api_key_auth]),
          RequestsGenerator.users_posts_index([:api_key_auth]),
          RequestsGenerator.users_posts_create([:api_key_auth]),
          RequestsGenerator.users_posts_update([:api_key_auth])
        ],
        errors: []
      }

      config = %{
        format: :swagger,
        information_source: Xcribe.Support.Information,
        json_library: Jason,
        output: output_path
      }

      expected_content = String.replace(@sample_swagger_output, ~r/\s/, "")

      io_output =
        capture_io(fn ->
          assert Xcribe.generate_doc(recorded, config) == :ok
        end)

      assert io_output =~ "Xcribe documentation written in"

      assert output_path |> File.read!() |> String.replace(~r/\s/, "") == expected_content
    end

    test "write documentation with api_blueprint format" do
      output_path = "/tmp/xcribe_test_#{:rand.uniform()}"

      recorded = %{
        records: [
          RequestsGenerator.users_index([:basic_auth]),
          RequestsGenerator.users_show([:basic_auth]),
          RequestsGenerator.users_create([:bearer_auth]),
          RequestsGenerator.users_update([:bearer_auth]),
          RequestsGenerator.users_delete([:bearer_auth]),
          RequestsGenerator.users_custom_action([:api_key_auth]),
          RequestsGenerator.users_posts_index([:api_key_auth]),
          RequestsGenerator.users_posts_create([:api_key_auth]),
          RequestsGenerator.users_posts_update([:api_key_auth])
        ],
        errors: []
      }

      config = %{
        format: :api_blueprint,
        information_source: Xcribe.Support.Information,
        json_library: Jason,
        output: output_path
      }

      io_output =
        capture_io(fn ->
          assert Xcribe.generate_doc(recorded, config) == :ok
        end)

      assert io_output =~ "Xcribe documentation written in"

      assert File.read!(output_path) == @sample_apib_output
    end

    test "handle parsing errors" do
      error = %Error{
        type: :parsing,
        message: "route not found",
        __meta__: %{
          call: %{
            description: "test name",
            file: File.cwd!() <> "/test/xcribe_test.exs",
            line: 1
          }
        }
      }

      recorded = %{
        records: [%Request{}],
        errors: [error]
      }

      assert capture_io(fn ->
               assert Xcribe.generate_doc(recorded, %{}) == {:error, [error]}
             end) == ""
    end

    test "handle parsing and validation errors" do
      parsing_error = %Error{
        type: :parsing,
        message: "route not found",
        __meta__: %{
          call: %{
            description: "test name",
            file: File.cwd!() <> "/test/xcribe_test.exs",
            line: 1
          }
        }
      }

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

      recorded = %{records: [invalid_request], errors: [parsing_error]}

      assert capture_io(fn ->
               assert {:error,
                       [
                         %Error{
                           message:
                             "The Plug.Conn params must be valid HTTP params. A struct Date was found!"
                         },
                         ^parsing_error
                       ]} = Xcribe.generate_doc(recorded, %{})
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

      recorded = %{records: [request_with_error], errors: []}

      config = %{
        format: :swagger,
        information_source: Xcribe.Support.Information,
        json_library: Jason
      }

      assert capture_io(fn ->
               assert {:error, %DocException{}} = Xcribe.generate_doc(recorded, config)
             end) == ""
    end
  end
end
