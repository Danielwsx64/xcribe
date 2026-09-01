defmodule Xcribe.APIModelTest do
  use ExUnit.Case, async: true

  alias Xcribe.APIModel
  alias Xcribe.APIModel.Body
  alias Xcribe.DocException

  alias Xcribe.Support.RequestsGenerator
  alias Xcribe.Support.Samples

  @config %{json_library: Jason}
  @specification %{ignore_namespaces: [], ignore_resources_prefix: []}

  describe "build/3" do
    test "return an empty model for no requests" do
      assert APIModel.build([], @specification, @config) == %APIModel{
               routes: [],
               schemas: %{},
               security_schemes: []
             }
    end

    test "group every request by path and verb" do
      model = APIModel.build(Samples.APIModel.all_requests(), @specification, @config)

      assert Enum.map(model.routes, &{&1.path, Enum.map(&1.operations, fn op -> op.verb end)}) ==
               Samples.APIModel.all_requests_paths_and_verbs()
    end

    test "collect every named schema into a single registry" do
      model = APIModel.build(Samples.APIModel.all_requests(), @specification, @config)

      assert model.schemas |> Map.keys() |> Enum.sort() ==
               Samples.APIModel.all_requests_schema_names()
    end

    test "union the properties of two requests sharing a schema name" do
      requests = [RequestsGenerator.users_show(), RequestsGenerator.users_update()]

      model = APIModel.build(requests, @specification, @config)

      assert model.schemas["Users"] == %{
               type: "object",
               properties: %{
                 "age" => %{type: "number", format: "int32", example: 5},
                 "id" => %{type: "number", format: "int32", example: 1},
                 "name" => %{type: "string", example: "user 1"}
               }
             }
    end

    test "union a collection response with a single object response sharing a schema name" do
      requests = [RequestsGenerator.users_index(), RequestsGenerator.users_update()]

      model = APIModel.build(requests, @specification, @config)

      assert model.schemas["Users"] == %{
               type: "object",
               properties: %{
                 "age" => %{type: "number", format: "int32", example: 5},
                 "id" => %{type: "number", format: "int32", example: 1},
                 "name" => %{type: "string", example: "user 1"}
               }
             }
    end

    test "register the item schema of a collection response and mark the body as a collection" do
      model = APIModel.build([RequestsGenerator.users_index()], @specification, @config)

      assert [%{operations: [%{responses: [%{content: [body]}]}]}] = model.routes

      assert %Body{
               content_type: "application/json",
               schema_name: "Users",
               collection: true,
               schema: %{type: "object"}
             } = body

      assert model.schemas["Users"] == body.schema
    end

    test "raise a doc exception carrying the metadata of the request that could not be modelled" do
      request = RequestsGenerator.users_index()
      request = %{request | path_params: nil, __meta__: %{call: %{file: "f.exs", line: 7}}}

      error =
        assert_raise DocException, fn -> APIModel.build([request], @specification, @config) end

      assert error.request_error.__meta__ == %{call: %{file: "f.exs", line: 7}}
      assert error.request_error.type == :exception
    end

    test "strip the ignored namespaces of the specification before grouping" do
      specification = %{ignore_namespaces: ["/namespace_ignored"], ignore_resources_prefix: []}

      model = APIModel.build([RequestsGenerator.notes_index()], specification, @config)

      assert [%{path: "/notes", operations: [%{resource: "Notes"}]}] = model.routes
    end

    test "collect every security scheme found in the requests" do
      requests = [
        RequestsGenerator.users_index([:bearer_auth]),
        RequestsGenerator.users_index([:basic_auth]),
        RequestsGenerator.users_index([:api_key_auth])
      ]

      assert APIModel.build(requests, @specification, @config).security_schemes == [
               :api_key,
               :basic,
               :bearer
             ]
    end

    test "collapse the requests of one route into one operation keeping every example" do
      requests = [
        RequestsGenerator.users_index([:bearer_auth]),
        RequestsGenerator.users_index([:basic_auth]),
        RequestsGenerator.users_index([:api_key_auth])
      ]

      assert [%{operations: [operation]}] =
               APIModel.build(requests, @specification, @config).routes

      assert length(operation.examples) == 3
      assert operation.security == [:api_key, :basic, :bearer]
    end

    test "build the same model whatever the order the requests were recorded in" do
      requests = Samples.APIModel.all_requests()
      expected = APIModel.build(requests, @specification, @config)

      for _attempt <- 1..10 do
        assert APIModel.build(Enum.shuffle(requests), @specification, @config) == expected
      end
    end
  end
end
