defmodule Xcribe.SwaggerTest do
  use ExUnit.Case, async: true

  alias Xcribe.Support.RequestsGenerator
  alias Xcribe.{DocException, Request, Swagger}

  @sample_swagger_output File.read!("test/support/swagger_example.json")

  setup do
    {:ok,
     %{config: %{specification_source: "test/support/.simple_example.exs", json_library: Jason}}}
  end

  describe "generate_doc/1" do
    test "parse requests do string", %{config: config} do
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

    test "when there is no security schema", %{config: config} do
      requests = [
        %Request{
          __meta__: %{},
          action: "index",
          controller: Elixir.Xcribe.ProtocolsController,
          description: "",
          header_params: [],
          params: %{},
          path: "/servers",
          path_params: %{},
          query_params: %{},
          request_body: %{},
          resource: ["protocols"],
          resp_body: "[{\"id\":2,\"name\":\"user 2\"}]",
          resp_headers: [
            {"content-type", "application/json"}
          ],
          status_code: 200,
          verb: "get"
        }
      ]

      expected = %{
        "components" => %{"securitySchemes" => %{}},
        "info" => %{
          "description" => "The description of the API",
          "title" => "Basic API",
          "version" => "1.0.0"
        },
        "openapi" => "3.0.3",
        "servers" => [%{"url" => "http://my-api.com"}],
        "paths" => %{
          "/servers" => %{
            "get" => %{
              "description" => "",
              "parameters" => [],
              "security" => [],
              "summary" => "",
              "tags" => [],
              "responses" => %{
                "200" => %{
                  "description" => "",
                  "headers" => %{},
                  "content" => %{
                    "application/json" => %{
                      "schema" => %{
                        "type" => "array",
                        "items" => %{
                          "type" => "object",
                          "properties" => %{
                            "id" => %{"format" => "int32", "type" => "number", "example" => 2},
                            "name" => %{"type" => "string", "example" => "user 2"}
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }

      assert result = Swagger.generate_doc(requests, config)

      assert Jason.decode!(result) == expected
    end

    test "handle excptions into Request Error structs", %{config: config} do
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
