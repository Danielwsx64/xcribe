defmodule Xcribe.Request.ValidatorTest do
  use ExUnit.Case, async: true

  alias Xcribe.Request
  alias Xcribe.Request.{Error, Validator}

  describe "validate/1" do
    test "return ok when request is valid" do
      request = %Request{
        action: "index",
        controller: Elixir.Xcribe.UsersController,
        description: "",
        header_params: [{"authorization", "token"}],
        params: %{},
        path: "/users",
        path_params: %{},
        query_params: %{},
        request_body: %{},
        resource: "users",
        resource_group: :api,
        resp_body: "[{\"id\":1,\"name\":\"user 1\"},{\"id\":2,\"name\":\"user 2\"}]",
        resp_headers: [
          {"content-type", "application/json; charset=utf-8"},
          {"cache-control", "max-age=0, private, must-revalidate"}
        ],
        status_code: 200,
        verb: "get"
      }

      assert Validator.validate(request) == {:ok, request}
    end

    test "return an error when request has a struct in path_params" do
      meta = %{metadata: "value"}
      request = %Request{path_params: ~D[2021-02-15], __meta__: meta}

      assert Validator.validate(request) ==
               {:error,
                %Error{
                  type: :validation,
                  message:
                    "The Plug.Conn params must be valid HTTP params. A struct Date was found!",
                  __meta__: meta
                }}
    end

    test "return an error when request has a struct in request_body" do
      meta = %{metadata: "value"}
      request = %Request{request_body: ~D[2021-02-15], __meta__: meta}

      assert Validator.validate(request) ==
               {:error,
                %Error{
                  type: :validation,
                  message:
                    "The Plug.Conn params must be valid HTTP params. A struct Date was found!",
                  __meta__: meta
                }}
    end

    test "return an error when request has a struct in header_params" do
      meta = %{metadata: "value"}
      request = %Request{header_params: ~D[2021-02-15], __meta__: meta}

      assert Validator.validate(request) ==
               {:error,
                %Error{
                  type: :validation,
                  message:
                    "The Plug.Conn params must be valid HTTP params. A struct Date was found!",
                  __meta__: meta
                }}
    end

    test "return an error when request has a struct in query_params" do
      meta = %{metadata: "value"}
      request = %Request{query_params: ~D[2021-02-15], __meta__: meta}

      assert Validator.validate(request) ==
               {:error,
                %Error{
                  type: :validation,
                  message:
                    "The Plug.Conn params must be valid HTTP params. A struct Date was found!",
                  __meta__: meta
                }}
    end

    test "params with nested struct" do
      request = %Request{
        request_body: %{
          date: ~D[2021-02-15]
        }
      }

      assert Validator.validate(request) ==
               {:error,
                %Xcribe.Request.Error{
                  message:
                    "The Plug.Conn params must be valid HTTP params. A struct Date was found!",
                  type: :validation
                }}
    end

    test "params with nested struct into list" do
      request = %Request{
        request_body: %{
          params: [
            1,
            %{
              date: ~D[2021-02-15]
            }
          ]
        }
      }

      assert Validator.validate(request) ==
               {:error,
                %Xcribe.Request.Error{
                  message:
                    "The Plug.Conn params must be valid HTTP params. A struct Date was found!",
                  type: :validation
                }}
    end
  end
end
