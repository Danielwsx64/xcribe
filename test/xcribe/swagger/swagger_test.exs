defmodule Xcribe.SwaggerTest do
  use ExUnit.Case, async: true

  alias Xcribe.Support.RequestsGenerator
  alias Xcribe.{DocException, Swagger}

  @sample_swagger_output File.read!("test/support/swagger_example.json")

  describe "generate_doc/1" do
    test "parse requests do string" do
      config = %{specification_source: "test/support/.simple_example.exs", json_library: Jason}

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

      expected = Jason.decode!(@sample_swagger_output)

      response = Swagger.generate_doc(requests, config)

      assert Jason.decode!(response) == expected
    end

    test "handle excptions into Request Error structs" do
      config = %{specification_source: "test/support/.simple_example.exs", json_library: Jason}

      request =
        [:basic_auth]
        |> RequestsGenerator.users_index()
        |> Map.put(:path_params, nil)
        |> Map.put(:__meta__, %{
          call: %{
            description: "conn test",
            file: File.cwd!() <> "/test/xcribe/cli/output_test.exs",
            line: 25
          }
        })

      assert_raise DocException, "An exception was raised. Elixir.Protocol.UndefinedError", fn ->
        Swagger.generate_doc([request], config)
      end
    end
  end
end
