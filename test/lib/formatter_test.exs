defmodule XcribeFormatterTest do
  use ExUnit.Case, async: false
  use Xcribe.SwaggerExamples
  use Xcribe.RequestsExamples
  use Xcribe.ApiBlueprintExamples

  import ExUnit.CaptureIO

  alias Xcribe.{Formatter, Recorder, Request, Request.Error}

  alias Xcribe.Support.RequestsGenerator

  @output_path "/tmp/test"

  setup do
    Application.put_env(:xcribe, :env_var, "PWD")
    Application.put_env(:xcribe, :output, @output_path)
    Application.put_env(:xcribe, :information_source, Xcribe.Support.Information)
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

      assert Formatter.handle_cast({:suite_finished, 1, 2}, nil) == {:noreply, nil}
      assert @output_path |> File.read!() |> String.replace(~r/\s/, "") == expected_content
    end

    test "api_blueprint format" do
      Enum.each(@sample_requests, &Recorder.save(&1))

      Application.put_env(:xcribe, :format, :api_blueprint)

      expected_content = @sample_requests_as_string

      assert Formatter.handle_cast({:suite_finished, 1, 2}, nil) == {:noreply, nil}
      assert File.read!(@output_path) == expected_content
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
            file: File.cwd!() <> "/test/lib/formatter_test.exs",
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
  end
end
