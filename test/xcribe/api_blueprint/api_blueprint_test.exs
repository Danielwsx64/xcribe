defmodule Xcribe.ApiBlueprintTest do
  use ExUnit.Case, async: true

  alias Xcribe.Support.RequestsGenerator
  alias Xcribe.{ApiBlueprint, DocException, Request}

  @sample_apib_output File.read!("test/support/api_blueprint_example.apib")

  setup do
    {:ok,
     %{config: %{specification_source: "test/support/.simple_example.exs", json_library: Jason}}}
  end

  describe "generate_doc/1" do
    test "generate doc", %{config: config} do
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

      assert ApiBlueprint.generate_doc(requests, config) == @sample_apib_output
    end

    test "handle exception", %{config: config} do
      requests = [
        %Request{
          __meta__: %{
            call: %{
              description: "conn test",
              file: File.cwd!() <> "/test/xcribe/cli/output_test.exs",
              line: 25
            }
          }
        }
      ]

      assert_raise DocException, "An exception was raised. Elixir.FunctionClauseError", fn ->
        ApiBlueprint.generate_doc(requests, config)
      end
    end
  end
end
