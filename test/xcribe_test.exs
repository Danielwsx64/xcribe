defmodule XcribeTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  alias Xcribe.{Recorder, Request, Request.Error}

  alias Xcribe.Support.RequestsGenerator

  @sample_swagger_output File.read!("test/support/swagger_example.json")
  @sample_apib_output File.read!("test/support/api_blueprint_example.apib")
  @output_path "/tmp/test"

  test "README install version check" do
    app = :xcribe

    app_version = "#{Application.spec(app, :vsn)}"
    readme = File.read!("README.md")
    [_, readme_versions] = Regex.run(~r/{:#{app}, "(.+)"}/, readme)

    assert Version.match?(app_version, readme_versions)
  end

  describe "suite_finished/0" do
    setup do
      Application.put_env(:xcribe, :output, @output_path)
      Application.put_env(:xcribe, :information_source, Xcribe.Support.Information)
      Application.put_env(:xcribe, :format, :swagger)
      Application.delete_env(:xcribe, :json_library)
      Recorder.pop_all()

      on_exit(fn ->
        Application.delete_env(:xcribe, :output)
        Application.delete_env(:xcribe, :information_source)
        Application.delete_env(:xcribe, :env_var)
      end)

      :ok
    end

    test "write documentation with swagger format" do
      Application.put_env(:xcribe, :format, :swagger)

      requests = [
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

      Enum.each(requests, &Recorder.add(&1))

      expected_content = String.replace(@sample_swagger_output, ~r/\s/, "")

      assert capture_io(fn ->
               assert Xcribe.suite_finished() == :ok
             end) =~ "Xcribe documentation written in"

      assert @output_path |> File.read!() |> String.replace(~r/\s/, "") == expected_content
    end

    test "write documentation with api_blueprint format" do
      Application.put_env(:xcribe, :format, :api_blueprint)

      requests = [
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

      Enum.each(requests, &Recorder.add(&1))

      assert capture_io(fn ->
               assert Xcribe.suite_finished() == :ok
             end) =~ "Xcribe documentation written in"

      assert File.read!(@output_path) == @sample_apib_output
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

      Recorder.add(%Request{})
      Recorder.add(error)

      output =
        capture_io(fn ->
          assert {:error, _errors_list} = Xcribe.suite_finished()
        end)

      assert output =~ "route not found"
      assert output =~ "xcribe_test.exs"
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

      validation_error = %Request{
        request_body: %{date: ~D[2021-01-01]},
        __meta__: %{
          call: %{
            description: "test name",
            file: File.cwd!() <> "/test/xcribe_test.exs",
            line: 1
          }
        }
      }

      Recorder.add(parsing_error)
      Recorder.add(validation_error)

      output =
        capture_io(fn ->
          assert {:error, _errors_list} = Xcribe.suite_finished()
        end)

      assert output =~ "route not found"
      assert output =~ "xcribe_test.exs"
      assert output =~ "The Plug.Conn params must be valid HTTP params"
    end

    test "handle invalid configuration" do
      Application.put_env(:xcribe, :format, :invalid)
      Application.put_env(:xcribe, :json_library, Fake)
      Application.put_env(:xcribe, :information_source, Fake)

      output =
        capture_io(fn ->
          assert {:error, _errors_list} = Xcribe.suite_finished()
        end)

      assert output =~ "Config key: json_library"
      assert output =~ "Config key: format"
      assert output =~ "Config key: information_source"
    end

    test "handle document exceptions" do
      Recorder.add(%Request{
        __meta__: %{
          call: %{
            description: "conn test",
            file: File.cwd!() <> "/test/xcribe/cli/output_test.exs",
            line: 25
          }
        }
      })

      Application.put_env(:xcribe, :format, :swagger)

      output =
        capture_io(fn ->
          assert Xcribe.suite_finished() ==
                   {:error, "An exception was raised. Elixir.FunctionClauseError"}
        end)

      assert output =~ "An exception was raised"
    end
  end
end
