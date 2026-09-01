defmodule Xcribe.APIModel.OperationTest do
  use ExUnit.Case, async: true

  alias Xcribe.APIModel.{Body, Operation, Parameter}

  alias Xcribe.Support.RequestsGenerator
  alias Xcribe.Support.Samples

  @config %{json_library: Jason}

  describe "from_request/2" do
    test "extract every documented value of a request" do
      request = RequestsGenerator.users_posts_create()

      assert Operation.from_request(request, @config) ==
               Samples.APIModel.users_posts_create_operation()
    end

    test "return no request content for a request without a body" do
      operation = Operation.from_request(RequestsGenerator.users_index(), @config)

      assert operation.request_content == []
    end

    test "return a response without content for an empty response body" do
      operation = Operation.from_request(RequestsGenerator.users_delete(), @config)

      assert [%{status: 204, content: []}] = operation.responses
      assert [%{response_body: nil, response_raw_body: ""}] = operation.examples
    end

    test "name the request and the response schemas from the request" do
      operation = Operation.from_request(RequestsGenerator.users_update(), @config)

      assert Enum.map(operation.request_content, & &1.schema_name) == ["updateUsers"]

      assert operation.responses |> hd() |> Map.get(:content) |> Enum.map(& &1.schema_name) == [
               "Users"
             ]
    end

    test "keep every header as a parameter" do
      operation = Operation.from_request(RequestsGenerator.users_index([:bearer_auth]), @config)

      assert Enum.map(operation.parameters, &Parameter.sort_key/1) == [
               {:header, "authorization"},
               {:header, "content-type"}
             ]
    end

    test "return the security kind of a bearer authorization header" do
      operation = Operation.from_request(RequestsGenerator.users_index([:bearer_auth]), @config)

      assert operation.security == [:bearer]
    end

    test "return the security kind of a basic authorization header" do
      operation = Operation.from_request(RequestsGenerator.users_index([:basic_auth]), @config)

      assert operation.security == [:basic]
    end

    test "return the security kind of an unknown authorization header" do
      operation = Operation.from_request(RequestsGenerator.users_index([:api_key_auth]), @config)

      assert operation.security == [:api_key]
    end

    test "return no security without an authorization header" do
      operation = Operation.from_request(RequestsGenerator.no_pipe_users_index(), @config)

      assert operation.security == []
    end

    test "report a missing content type instead of decoding the response" do
      request = %{RequestsGenerator.users_index() | resp_headers: []}

      assert [example] = Operation.from_request(request, @config).examples
      assert example.response_decode_error == :missing_content_type
      assert example.response_body == nil
    end

    test "report an unknown content type instead of decoding the response" do
      request = %{RequestsGenerator.users_index() | resp_headers: [{"content-type", "text/html"}]}

      assert [example] = Operation.from_request(request, @config).examples
      assert example.response_decode_error == {:unknown_content_type, "text/html"}
      assert example.response_body == nil
    end
  end

  describe "merge/2" do
    test "collect the descriptions, the tags and the security of both operations" do
      base = Operation.from_request(RequestsGenerator.users_index([:bearer_auth]), @config)

      new =
        RequestsGenerator.users_index([
          :basic_auth,
          description: "list users",
          groups_tags: ["Api"]
        ])

      merged = Operation.merge(base, Operation.from_request(new, @config))

      assert merged.descriptions == ["list users", "show users"]
      assert merged.tags == ["Api", "Users"]
      assert merged.security == [:basic, :bearer]
    end

    test "collect an example for every merged request" do
      operation = Operation.from_request(RequestsGenerator.users_index(), @config)

      assert operation |> Operation.merge(operation) |> Map.get(:examples) |> length() == 2
    end

    test "union the parameter examples of both operations" do
      base = Operation.from_request(RequestsGenerator.users_index([:bearer_auth]), @config)
      new = Operation.from_request(RequestsGenerator.users_index([:basic_auth]), @config)

      assert [authorization, _content_type] = Operation.merge(base, new).parameters
      assert length(authorization.examples) == 2
    end

    test "keep one response per status" do
      base = Operation.from_request(RequestsGenerator.users_index(), @config)
      new = Operation.from_request(RequestsGenerator.users_create(), @config)

      assert Operation.merge(base, new) |> Map.get(:responses) |> Enum.map(& &1.status) == [
               200,
               201
             ]
    end

    test "merge the request content of the same content type" do
      base = Operation.from_request(RequestsGenerator.users_create(), @config)
      new = Operation.from_request(RequestsGenerator.users_create(), @config)

      assert [%Body{content_type: "application/json"}] =
               Operation.merge(base, new).request_content
    end

    test "keep the scalar values of the base operation" do
      base = Operation.from_request(RequestsGenerator.users_index(), @config)
      new = Operation.from_request(RequestsGenerator.users_create(), @config)

      merged = Operation.merge(base, new)

      assert merged.verb == "get"
      assert merged.action == "index"
      assert merged.resource == "Users"
    end
  end

  describe "sort_key/1" do
    test "return the verb" do
      operation = Operation.from_request(RequestsGenerator.users_create(), @config)

      assert Operation.sort_key(operation) == "post"
    end
  end
end
