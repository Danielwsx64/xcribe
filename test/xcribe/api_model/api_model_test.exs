defmodule Xcribe.APIModelTest do
  use ExUnit.Case, async: true

  alias Xcribe.APIModel

  alias Xcribe.Support.RequestsGenerator
  alias Xcribe.Support.Samples

  @config %{json_library: Jason}

  describe "build/2" do
    test "return an empty model for no requests" do
      assert APIModel.build([], @config) == %APIModel{
               routes: [],
               schemas: %{},
               security_schemes: []
             }
    end

    test "group every request by path and verb" do
      model = APIModel.build(Samples.APIModel.all_requests(), @config)

      assert Enum.map(model.routes, &{&1.path, Enum.map(&1.operations, fn op -> op.verb end)}) ==
               Samples.APIModel.all_requests_paths_and_verbs()
    end

    test "collect every named schema into a single registry" do
      model = APIModel.build(Samples.APIModel.all_requests(), @config)

      assert model.schemas |> Map.keys() |> Enum.sort() ==
               Samples.APIModel.all_requests_schema_names()
    end

    test "union the properties of two requests sharing a schema name" do
      requests = [RequestsGenerator.users_show(), RequestsGenerator.users_update()]

      model = APIModel.build(requests, @config)

      assert model.schemas["Users"] == %{
               type: "object",
               properties: %{
                 "age" => %{type: "number", format: "int32", example: 5},
                 "id" => %{type: "number", format: "int32", example: 1},
                 "name" => %{type: "string", example: "user 1"}
               }
             }
    end

    test "keep the last schema when two requests sharing a name have different types" do
      requests = [RequestsGenerator.users_index(), RequestsGenerator.users_show()]

      model = APIModel.build(requests, @config)

      assert model.schemas["Users"] == %{
               type: "object",
               properties: %{
                 "id" => %{type: "number", format: "int32", example: 1},
                 "name" => %{type: "string", example: "user 1"}
               }
             }
    end

    test "collect every security scheme found in the requests" do
      requests = [
        RequestsGenerator.users_index([:bearer_auth]),
        RequestsGenerator.users_index([:basic_auth]),
        RequestsGenerator.users_index([:api_key_auth])
      ]

      assert APIModel.build(requests, @config).security_schemes == [:api_key, :basic, :bearer]
    end

    test "collapse the requests of one route into one operation keeping every example" do
      requests = [
        RequestsGenerator.users_index([:bearer_auth]),
        RequestsGenerator.users_index([:basic_auth]),
        RequestsGenerator.users_index([:api_key_auth])
      ]

      assert [%{operations: [operation]}] = APIModel.build(requests, @config).routes
      assert length(operation.examples) == 3
      assert operation.security == [:api_key, :basic, :bearer]
    end

    test "build the same model whatever the order the requests were recorded in" do
      requests = Samples.APIModel.all_requests()
      expected = APIModel.build(requests, @config)

      for _attempt <- 1..10 do
        assert APIModel.build(Enum.shuffle(requests), @config) == expected
      end
    end
  end
end
