defmodule Xcribe.SwaggerTest do
  use ExUnit.Case, async: true
  use Xcribe.RequestsExamples
  use Xcribe.SwaggerExamples

  alias Xcribe.Support.RequestsGenerator
  alias Xcribe.{DocException, Swagger}

  setup do
    Application.put_env(:xcribe, :information_source, Xcribe.Support.Information)

    :ok
  end

  describe "generate_doc/1" do
    test "parse requests do string" do
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

      response = Swagger.generate_doc(requests)

      assert Jason.decode!(response) == expected
    end

    test "when there is no security schema" do
      requests = [
        %Request{
          action: "index",
          controller: Elixir.Xcribe.ProtocolsController,
          description: "",
          header_params: [],
          params: %{},
          path: "/servers",
          path_params: %{},
          query_params: %{},
          request_body: %{},
          resource: "protocols",
          resource_group: :api,
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
          "version" => "1"
        },
        "openapi" => "3.0.3",
        "servers" => [%{"description" => "", "url" => "http://my-api.com"}],
        "paths" => %{
          "/servers" => %{
            "get" => %{
              "description" => "",
              "parameters" => [],
              "security" => [],
              "summary" => "",
              "tags" => ["protocols"],
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

      assert Jason.decode!(Swagger.generate_doc(requests)) == expected
    end

    test "handle excptions into Request Error structs" do
      request =
        [:basic_auth]
        |> RequestsGenerator.users_index()
        |> Map.put(:path_params, nil)
        |> Map.put(:__meta__, %{
          call: %{
            description: "conn test",
            file: File.cwd!() <> "/test/lib/cli/output_test.exs",
            line: 25
          }
        })

      assert_raise DocException, "An exception was raised. Elixir.Protocol.UndefinedError", fn ->
        Swagger.generate_doc([request])
      end
    end
  end
end
