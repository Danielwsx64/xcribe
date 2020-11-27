defmodule Xcribe.FormatterTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  alias Xcribe.{Formatter, Recorder, Request, Request.Error}

  alias Xcribe.Support.RequestsGenerator

  @sample_swagger_output File.read!("test/support/swagger_example.json")
  @sample_apib_output File.read!("test/support/api_blueprint_example.apib")
  @output_path "/tmp/test"

  setup do
    Application.put_env(:xcribe, :env_var, "PWD")
    Application.put_env(:xcribe, :output, @output_path)
    Application.put_env(:xcribe, :information_source, Xcribe.Support.Information)
    Application.put_env(:xcribe, :format, :swagger)
    Application.delete_env(:xcribe, :json_library)

    Recorder.start_link()

    on_exit(fn ->
      Application.delete_env(:xcribe, :env_var)
      Application.delete_env(:xcribe, :output)
      Application.delete_env(:xcribe, :information_source)
    end)

    :ok
  end

  describe "write document" do
    test "swagger format" do
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

      Enum.each(requests, &Recorder.save(&1))

      Application.put_env(:xcribe, :format, :swagger)

      expected_content = String.replace(@sample_swagger_output, ~r/\s/, "")

      assert capture_io(fn ->
               assert Formatter.handle_cast({:suite_finished, 1, 2}, nil) == {:noreply, nil}
             end) =~ "Xcribe documentation written in"

      assert @output_path |> File.read!() |> String.replace(~r/\s/, "") == expected_content
    end

    test "api_blueprint format" do
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

      Enum.each(requests, &Recorder.save(&1))

      Application.put_env(:xcribe, :format, :api_blueprint)

      assert capture_io(fn ->
               assert Formatter.handle_cast({:suite_finished, 1, 2}, nil) == {:noreply, nil}
             end) =~ "Xcribe documentation written in"

      assert File.read!(@output_path) == @sample_apib_output
    end
  end

  describe "handling request errors" do
    test "handle parsing errors" do
      error = %Error{
        type: :parsing,
        message: "route not found",
        __meta__: %{
          call: %{
            description: "test name",
            file: File.cwd!() <> "/test/xcribe/formatter_test.exs",
            line: 1
          }
        }
      }

      Recorder.save(%Request{})
      Recorder.save(error)

      output =
        capture_io(fn ->
          assert Formatter.handle_cast({:suite_finished, 1, 2}, nil) == {:noreply, nil}
        end)

      assert output =~ "route not found"
      assert output =~ "formatter_test.exs"
    end

    test "handle parsing and validation errors" do
      parsing_error = %Error{
        type: :parsing,
        message: "route not found",
        __meta__: %{
          call: %{
            description: "test name",
            file: File.cwd!() <> "/test/xcribe/formatter_test.exs",
            line: 1
          }
        }
      }

      validation_error = %Error{
        type: :validation,
        message:
          "The Plug.Conn params must be valid HTTP params. A struct Elixir.Date was found!",
        __meta__: %{
          call: %{
            description: "test name",
            file: File.cwd!() <> "/test/xcribe/formatter_test.exs",
            line: 1
          }
        }
      }

      Recorder.save(%Request{})
      Recorder.save(parsing_error)
      Recorder.save(validation_error)

      output =
        capture_io(fn ->
          assert Formatter.handle_cast({:suite_finished, 1, 2}, nil) == {:noreply, nil}
        end)

      assert output =~ "route not found"
      assert output =~ "formatter_test.exs"
      assert output =~ "The Plug.Conn params must be valid HTTP params"
    end

    test "handle invalid configuration" do
      Application.put_env(:xcribe, :format, :invalid)
      Application.put_env(:xcribe, :json_library, Fake)
      Application.put_env(:xcribe, :information_source, Fake)

      output =
        capture_io(fn ->
          assert Formatter.handle_cast({:suite_finished, 1, 2}, nil) == {:noreply, nil}
        end)

      assert output =~ "Config key: json_library"
      assert output =~ "Config key: format"
      assert output =~ "Config key: information_source"
    end

    test "handle document exceptions" do
      Recorder.save(%Request{
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
          assert Formatter.handle_cast({:suite_finished, 1, 2}, nil) == {:noreply, nil}
        end)

      assert output =~ "An exception was raised"
    end
  end
end
