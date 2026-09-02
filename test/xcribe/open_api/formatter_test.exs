defmodule Xcribe.OpenAPI.FormatterTest do
  use ExUnit.Case, async: true

  alias Plug.Upload
  alias Xcribe.APIModel
  alias Xcribe.OpenAPI.Formatter
  alias Xcribe.Request
  alias Xcribe.Support.Samples

  @config %{json_library: Jason}
  @specification %{ignore_namespaces: [], ignore_resources_prefix: [], schemas: %{}}

  describe "openapi_object/1" do
    test "return an OpenAPI object with specifications" do
      specifications = %{
        name: "Xcribe API",
        description: "Cool api",
        version: "1.0.0",
        servers: [%{url: "https://sandbox.xcribe.com/v1", description: "sandbox endpoint"}],
        paths: %{},
        schemas: %{}
      }

      assert Formatter.openapi_object(specifications) == %{
               openapi: "3.0.3",
               info: %{description: "Cool api", title: "Xcribe API", version: "1.0.0"},
               servers: [%{description: "sandbox endpoint", url: "https://sandbox.xcribe.com/v1"}],
               components: nil,
               paths: nil
             }
    end
  end

  describe "operation_object/1" do
    test "return an operation object with parameters, security, tags and a collection response" do
      operation = Samples.APIModel.operation(users_index_request())

      assert Formatter.operation_object(operation) == %{
               description: "Get users",
               parameters: [
                 %{
                   example: %{"articles" => "title,body", "people" => "name"},
                   in: "query",
                   name: "fields",
                   schema: %{
                     properties: %{"articles" => %{type: "string"}, "people" => %{type: "string"}},
                     type: "object"
                   }
                 },
                 %{example: "author", in: "query", name: "include", schema: %{type: "string"}}
               ],
               security: [%{api_key: []}],
               tags: ["Users"],
               responses: %{
                 200 => %{
                   description: "",
                   headers: %{"cache-control" => %{schema: %{type: "string"}}},
                   content: %{
                     "application/json" => %{
                       schema: %{type: "array", items: %{"$ref" => "#/components/schemas/Users"}}
                     }
                   }
                 }
               }
             }
    end

    test "reference the request schema when the request had a body" do
      operation = Samples.APIModel.operation(users_create_request())

      assert Formatter.operation_object(operation) == %{
               description: "",
               parameters: [],
               security: [],
               tags: ["Users"],
               requestBody: %{
                 content: %{
                   "application/json" => %{
                     schema: %{"$ref" => "#/components/schemas/createUsers"}
                   }
                 }
               },
               responses: %{
                 201 => %{
                   description: "",
                   headers: %{},
                   content: %{
                     "application/json" => %{schema: %{"$ref" => "#/components/schemas/Users"}}
                   }
                 }
               }
             }
    end

    test "omit the response content of a request with no body" do
      operation = Samples.APIModel.operation(users_delete_request())

      assert Formatter.operation_object(operation) == %{
               description: "",
               parameters: [%{example: "1", in: "query", name: "id", schema: %{type: "string"}}],
               security: [],
               tags: [],
               responses: %{
                 204 => %{
                   description: "",
                   headers: %{"cache-control" => %{schema: %{type: "string"}}}
                 }
               }
             }
    end

    test "reference the request schema of an upload body" do
      operation = Samples.APIModel.operation(users_upload_request())

      assert Formatter.operation_object(operation) == %{
               description: "",
               parameters: [],
               security: [],
               tags: ["Users"],
               requestBody: %{
                 content: %{
                   "multipart/form-data" => %{
                     schema: %{"$ref" => "#/components/schemas/updateUsers"}
                   }
                 }
               },
               responses: %{
                 200 => %{
                   description: "",
                   headers: %{},
                   content: %{
                     "application/json" => %{schema: %{"$ref" => "#/components/schemas/Users"}}
                   }
                 }
               }
             }
    end

    test "drop the content type, the authorization and the accept header parameters" do
      request = %{
        users_delete_request()
        | header_params: [
            {"accept", "application/json"},
            {"authorization", "token"},
            {"content-type", "application/json"},
            {"x-request-id", "abc"}
          ],
          query_params: %{}
      }

      operation = Samples.APIModel.operation(request)

      assert Formatter.operation_object(operation).parameters == [
               %{example: "abc", in: "header", name: "x-request-id", schema: %{type: "string"}}
             ]
    end

    test "describe both schemas with oneOf when one status answers two of them" do
      requests = [
        %{users_create_request() | schema: "UserA"},
        %{users_create_request() | schema: "UserB"}
      ]

      assert [%{operations: [operation]}] =
               APIModel.build(requests, @specification, @config).routes

      assert Formatter.operation_object(operation).responses[201].content == %{
               "application/json" => %{
                 schema: %{
                   oneOf: [
                     %{"$ref" => "#/components/schemas/UserA"},
                     %{"$ref" => "#/components/schemas/UserB"}
                   ]
                 }
               }
             }
    end
  end

  describe "components_object/2" do
    test "collect every schema an operation references" do
      model = APIModel.build([users_upload_request()], @specification, @config)

      assert Formatter.components_object(model, @specification) == %{
               securitySchemes: %{},
               schemas: %{
                 "Users" => %{
                   properties: %{"name" => %{example: "user 1", type: "string"}},
                   type: "object"
                 },
                 "updateUsers" => %{
                   properties: %{
                     "file" => %{format: "binary", type: "string"},
                     "user_id" => %{example: "123", type: "string"}
                   },
                   type: "object"
                 }
               }
             }
    end

    test "keep the schemas of the specification as the base of the generated ones" do
      specification = %{
        @specification
        | schemas: %{"Users" => %{type: "object", description: "Every user"}}
      }

      model = APIModel.build([users_index_request()], specification, @config)

      assert Formatter.components_object(model, specification).schemas == %{
               "Users" => %{
                 type: "object",
                 description: "Every user",
                 properties: %{
                   "id" => %{format: "int32", type: "number", example: 1},
                   "name" => %{type: "string", example: "user 1"}
                 }
               }
             }
    end

    test "omit a schema no operation references" do
      request = %{
        users_delete_request()
        | status_code: 200,
          resp_body: "the body",
          resp_headers: [{"content-type", "text/plain"}]
      }

      model = APIModel.build([request], @specification, @config)

      assert model.schemas |> Map.keys() == ["Users"]
      assert Formatter.components_object(model, @specification).schemas == %{}
    end

    test "collect the security scheme of every operation" do
      requests = [
        %{users_index_request() | header_params: [{"authorization", "Bearer token"}]},
        %{users_create_request() | header_params: [{"authorization", "Basic token"}]}
      ]

      model = APIModel.build(requests, @specification, @config)

      assert Formatter.components_object(model, @specification).securitySchemes == %{
               "basic" => %{type: "http", scheme: "basic"},
               "bearer" => %{type: "http", scheme: "bearer", bearerFormat: "JWT"}
             }
    end
  end

  defp users_index_request do
    %Request{
      path: "/users",
      header_params: [
        {"authorization", "token"},
        {"content-type", "application/json; charset=utf-8"}
      ],
      description: "Get users",
      groups_tags: ["Users"],
      path_params: %{},
      request_body: %{},
      resp_body: ~s([{"id":1,"name":"user 1"},{"id":2,"name":"user 2"}]),
      resp_headers: [
        {"content-type", "application/json; charset=utf-8"},
        {"cache-control", "max-age=0, private, must-revalidate"}
      ],
      status_code: 200,
      verb: "get",
      resource: "Users",
      schema: "Users",
      query_params: %{
        "fields" => %{"articles" => "title,body", "people" => "name"},
        "include" => "author"
      }
    }
  end

  defp users_create_request do
    %Request{
      path: "/users",
      description: "",
      header_params: [{"content-type", "application/json; charset=utf-8"}],
      groups_tags: ["Users"],
      path_params: %{},
      request_body: %{"name" => "Jonny"},
      resp_body: ~s({"name":"user 1"}),
      resp_headers: [{"content-type", "application/json; charset=utf-8"}],
      status_code: 201,
      verb: "post",
      resource: "Users",
      req_schema: "createUsers",
      schema: "Users",
      query_params: %{}
    }
  end

  defp users_delete_request do
    %Request{
      path: "/users/{id}",
      description: "",
      header_params: [{"content-type", "application/json; charset=utf-8"}],
      path_params: %{},
      query_params: %{"id" => "1"},
      request_body: %{},
      resource: "Users",
      status_code: 204,
      verb: "delete",
      resp_body: "",
      resp_headers: [
        {"content-type", "application/json; charset=utf-8"},
        {"cache-control", "max-age=0, private, must-revalidate"}
      ]
    }
  end

  defp users_upload_request do
    %Request{
      path: "/users",
      description: "",
      groups_tags: ["Users"],
      header_params: [{"content-type", "multipart/form-data; boundary=---boundary"}],
      path_params: %{},
      query_params: %{},
      request_body: %{
        "user_id" => "123",
        "file" => %Upload{
          content_type: "image/png",
          filename: "screenshot.png",
          path: "/tmp/multipart-id"
        }
      },
      status_code: 200,
      resp_body: ~s({"name":"user 1"}),
      resp_headers: [{"content-type", "application/json; charset=utf-8"}],
      verb: "put",
      resource: "Users",
      schema: "Users",
      req_schema: "updateUsers"
    }
  end
end
