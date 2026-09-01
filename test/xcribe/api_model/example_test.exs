defmodule Xcribe.APIModel.ExampleTest do
  use ExUnit.Case, async: true

  alias Xcribe.APIModel.Example

  alias Xcribe.Support.RequestsGenerator

  describe "from_request/3" do
    test "extract every recorded value of a request with a body" do
      request = RequestsGenerator.users_create()

      assert Example.from_request(request, %{"age" => 5, "name" => "user 1"}, nil) == %Example{
               __meta__: %{},
               description: "create user",
               status: 201,
               path_params: %{},
               query_params: %{},
               request_content_type: "application/json",
               request_schema_name: nil,
               response_schema_name: nil,
               request_headers: [{"content-type", "application/json"}],
               request_body: %{"age" => 5, "name" => "user 1"},
               response_content_type: "application/json",
               response_headers: [
                 {"cache-control", "max-age=0, private, must-revalidate"},
                 {"content-type", "application/json; charset=utf-8"}
               ],
               response_raw_body: ~s({"age":5,"name":"user 1"}),
               response_body: %{"age" => 5, "name" => "user 1"},
               response_decode_error: nil
             }
    end

    test "keep the path parameters of a request" do
      request = RequestsGenerator.users_show()

      assert Example.from_request(request, nil, nil).path_params == %{"id" => "1"}
    end

    test "keep the raw response body when the content could not be decoded" do
      request = RequestsGenerator.users_index()
      error = {:unknown_content_type, "application/xml"}

      example = Example.from_request(request, nil, error)

      assert example.response_body == nil
      assert example.response_decode_error == error
      assert example.response_raw_body == request.resp_body
    end

    test "keep the schema names the consumer declared" do
      request = RequestsGenerator.users_create(schema: "Users", req_schema: "createUsers")

      example = Example.from_request(request, nil, nil)

      assert example.request_schema_name == "createUsers"
      assert example.response_schema_name == "Users"
    end

    test "keep the schema names empty when the consumer declared none" do
      example = Example.from_request(RequestsGenerator.users_create(), nil, nil)

      assert example.request_schema_name == nil
      assert example.response_schema_name == nil
    end

    test "keep the call site metadata of the request" do
      meta = %{call: %{description: "test create user", file: "users_test.exs", line: 12}}
      request = %{RequestsGenerator.users_create() | __meta__: meta}

      assert Example.from_request(request, nil, nil).__meta__ == meta
    end
  end

  describe "sort_key/1" do
    test "return the status, the description and the call site" do
      meta = %{call: %{description: "test create user", file: "users_test.exs", line: 12}}
      request = %{RequestsGenerator.users_create() | __meta__: meta}

      assert Example.sort_key(Example.from_request(request, nil, nil)) ==
               {201, "create user", "users_test.exs", 12}
    end

    test "return an empty call site when the request carries no metadata" do
      request = RequestsGenerator.users_create()

      assert Example.sort_key(Example.from_request(request, nil, nil)) ==
               {201, "create user", "", 0}
    end
  end
end
