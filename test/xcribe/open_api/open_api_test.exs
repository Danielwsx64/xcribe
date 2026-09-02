defmodule Xcribe.OpenAPITest do
  use ExUnit.Case, async: true

  alias Xcribe.{APIModel, DocException, OpenAPI, Request, Specification}
  alias Xcribe.Support.RequestsGenerator

  @sample_openapi_output File.read!("test/support/openapi_example.json")

  describe "generate_doc/3" do
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

      expected = Jason.decode!(@sample_openapi_output)

      response = generate_doc(requests, config)

      assert Jason.decode!(response) == expected
    end

    test "document a request without groups tags" do
      config = %{specification_source: "test/support/.simple_example.exs", json_library: Jason}

      requests = [RequestsGenerator.users_index(groups_tags: [])]

      assert %{"paths" => %{"/users" => %{"get" => %{"tags" => []}}}} =
               requests |> generate_doc(config) |> Jason.decode!()
    end

    test "use the description of a specified path" do
      config = %{specification_source: "test/support/.paths_example.exs", json_library: Jason}

      doc =
        [RequestsGenerator.users_index()]
        |> generate_doc(config)
        |> Jason.decode!()

      assert get_in(doc, ["paths", "/users", "get", "description"]) ==
               "List every user in the account"
    end

    test "strip ignored namespaces and resource prefixes" do
      config = %{specification_source: "test/support/.ignore_example.exs", json_library: Jason}

      doc =
        [
          RequestsGenerator.notes_index(),
          RequestsGenerator.namespaced_users_index(),
          RequestsGenerator.users_posts_index()
        ]
        |> generate_doc(config)
        |> Jason.decode!()

      assert doc["paths"] |> Map.keys() |> Enum.sort() == [
               "/notes",
               "/users",
               "/users/{users_id}/posts"
             ]

      assert doc["paths"]["/notes"]["get"]["tags"] == ["Notes"]
      assert doc["paths"]["/users/{users_id}/posts"]["get"]["tags"] == ["Posts"]

      # A `paths:` key matches the stripped path, so no phantom `/namespace_ignored/notes` appears.
      assert doc["paths"]["/notes"]["get"]["description"] ==
               "Keyed by the stripped path, not the routed one"
    end

    test "when there is no security schema" do
      config = %{specification_source: "test/support/.simple_example.exs", json_library: Jason}

      requests = [
        %Request{
          __meta__: %{},
          action: "index",
          controller: Xcribe.ProtocolsController,
          description: "",
          header_params: [],
          params: %{},
          path: "/servers",
          path_params: %{},
          query_params: %{},
          request_body: %{},
          resource: "Protocols",
          resp_body: ~s([{"id":2,"name":"user 2"}]),
          resp_headers: [{"content-type", "application/json"}],
          status_code: 200,
          verb: "get"
        }
      ]

      doc = requests |> generate_doc(config) |> Jason.decode!()

      assert doc["components"]["securitySchemes"] == %{}
      assert doc["paths"]["/servers"]["get"]["security"] == []
      assert doc["paths"]["/servers"]["get"]["tags"] == []

      assert doc["paths"]["/servers"]["get"]["responses"]["200"]["content"]["application/json"] ==
               %{
                 "schema" => %{
                   "type" => "array",
                   "items" => %{"$ref" => "#/components/schemas/Protocols"}
                 }
               }
    end

    test "enrich a generated schema with one from the specification" do
      config = %{specification_source: "test/support/.schemas_example.exs", json_library: Jason}

      doc =
        [RequestsGenerator.users_index()]
        |> generate_doc(config)
        |> Jason.decode!()

      assert doc["components"]["schemas"]["Users"] == %{
               "type" => "object",
               "description" => "Every user in the account",
               "properties" => %{
                 "id" => %{"type" => "number", "format" => "int32", "example" => 1},
                 "name" => %{"type" => "string", "example" => "user 1"}
               }
             }
    end

    test "generate the same document whatever the order the requests were recorded in" do
      config = %{specification_source: "test/support/.simple_example.exs", json_library: Jason}

      requests = [
        RequestsGenerator.users_index([:basic_auth]),
        RequestsGenerator.users_show([:basic_auth]),
        RequestsGenerator.users_create([:bearer_auth]),
        RequestsGenerator.users_posts_index([:api_key_auth])
      ]

      expected = generate_doc(requests, config)

      for _attempt <- 1..10 do
        assert generate_doc(Enum.shuffle(requests), config) == expected
      end
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
        generate_doc([request], config)
      end
    end
  end

  defp generate_doc(requests, config) do
    specification = Specification.api_specification(config)

    requests
    |> APIModel.build(specification, config)
    |> OpenAPI.generate_doc(specification, config)
  end
end
