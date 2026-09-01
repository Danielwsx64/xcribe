defmodule Xcribe.ApiBlueprint.FormatterTest do
  use ExUnit.Case, async: true

  alias Plug.Upload
  alias Xcribe.ApiBlueprint.{Formatter, Multipart}
  alias Xcribe.APIModel
  alias Xcribe.Request
  alias Xcribe.Support.{RequestsGenerator, Samples}

  @config %{json_library: Jason}
  @specification %{ignore_namespaces: [], ignore_resources_prefix: []}

  describe "put_operation_into_groups/3" do
    test "add an operation under its group tag" do
      operation = Samples.APIModel.operation(RequestsGenerator.users_index())

      assert Formatter.put_operation_into_groups(%{}, operation) == %{
               "Users" => %{resources: Formatter.resource_object(operation)}
             }
    end

    test "add an operation with many group tags under each one of them" do
      operation =
        Samples.APIModel.operation(
          RequestsGenerator.users_index(groups_tags: ["Users", "Public API"])
        )

      resources = Formatter.resource_object(operation)

      assert Formatter.put_operation_into_groups(%{}, operation) == %{
               "Users" => %{resources: resources},
               "Public API" => %{resources: resources}
             }
    end

    test "add an operation without group tags to the untagged group" do
      operation = Samples.APIModel.operation(RequestsGenerator.users_index(groups_tags: []))

      assert Formatter.put_operation_into_groups(%{}, operation) == %{
               "" => %{resources: Formatter.resource_object(operation)}
             }
    end

    test "collect the actions of two operations sharing a resource" do
      requests = [RequestsGenerator.users_index(), RequestsGenerator.users_show()]

      operations =
        requests
        |> APIModel.build(@specification, @config)
        |> Map.fetch!(:routes)
        |> Enum.flat_map(& &1.operations)

      groups = Enum.reduce(operations, %{}, &Formatter.put_operation_into_groups(&2, &1))

      assert %{"Users" => %{resources: %{"/users" => resource}}} = groups
      assert resource.name == "Users"
      assert resource.actions |> Map.keys() |> Enum.sort() == ["GET /users", "GET /users/{id}"]
    end

    test "keep one request per description when two examples share it" do
      base = RequestsGenerator.users_index()

      requests = [
        %{base | description: "show users", status_code: 200},
        %{base | description: "show users", status_code: 404}
      ]

      assert [%{operations: [operation]}] =
               APIModel.build(requests, @specification, @config).routes

      assert length(operation.examples) == 2

      assert %{"Users" => %{resources: %{"/users" => %{actions: %{"GET /users" => action}}}}} =
               Formatter.put_operation_into_groups(%{}, operation)

      assert action.requests |> Map.keys() == ["show users"]
      assert action.requests["show users"].response.status == 404
    end

    test "collect every example of one action" do
      base = RequestsGenerator.users_index()

      requests = [
        %{base | description: "Cool description", query_params: %{"user_age" => "32"}},
        %{base | description: "Other description", query_params: %{"limit" => "5"}}
      ]

      assert [%{operations: [operation]}] =
               APIModel.build(requests, @specification, @config).routes

      assert %{"Users" => %{resources: %{"/users" => resource}}} =
               Formatter.put_operation_into_groups(%{}, operation)

      assert %{"GET /users" => action} = resource.actions

      assert action.query_parameters == %{
               "limit" => %{example: "5", type: "string"},
               "user_age" => %{example: "32", type: "string"}
             }

      assert action.requests |> Map.keys() |> Enum.sort() == [
               "Cool description",
               "Other description"
             ]
    end
  end

  describe "resource_object/2" do
    test "return the resource with its uri parameters and its actions" do
      operation = Samples.APIModel.operation(users_posts_show_request())

      assert Formatter.resource_object(operation) == %{
               "/users/{usersId}/posts" => %{
                 name: "Users Posts",
                 parameters: %{"usersId" => %{example: "1", required: true, type: "string"}},
                 actions: Formatter.action_object(operation)
               }
             }
    end
  end

  describe "action_object/2" do
    test "return the action with its parameters and its requests" do
      operation = Samples.APIModel.operation(users_posts_show_request())
      [example] = operation.examples

      assert Formatter.action_object(operation) == %{
               "GET /users/{usersId}/posts/{id}" => %{
                 name: "Users Posts show",
                 description: "",
                 parameters: %{
                   "id" => %{example: "2", required: true, type: "string"},
                   "usersId" => %{example: "1", required: true, type: "string"}
                 },
                 query_parameters: %{"user_age" => %{example: "34", type: "string"}},
                 requests: %{"get all user posts" => Formatter.request_object(example)}
               }
             }
    end

    test "return the given action description" do
      operation = Samples.APIModel.operation(users_posts_show_request())

      assert %{"GET /users/{usersId}/posts/{id}" => %{description: "List every post"}} =
               Formatter.action_object(operation, "List every post")
    end
  end

  describe "request_objects/1" do
    test "key every request by the description of its example" do
      operation = Samples.APIModel.operation(users_posts_show_request())
      [example] = operation.examples

      assert Formatter.request_objects(operation.examples) == %{
               "get all user posts" => Formatter.request_object(example)
             }
    end
  end

  describe "request_object/1" do
    test "return the request with its headers, body, schema and response" do
      example = Samples.APIModel.example(users_create_request())

      assert Formatter.request_object(example) == %{
               content_type: "application/json",
               headers: %{"authorization" => "token"},
               body: %{"age" => 5, "name" => "teste"},
               schema: %{
                 type: "object",
                 properties: %{
                   "age" => %{example: 5, format: "int32", type: "number"},
                   "name" => %{example: "teste", type: "string"}
                 }
               },
               response: %{
                 content_type: "application/json",
                 headers: %{},
                 body: %{"age" => 5, "name" => "teste"},
                 schema: %{
                   properties: %{
                     "age" => %{example: 5, format: "int32", type: "number"},
                     "name" => %{example: "teste", type: "string"}
                   },
                   type: "object"
                 },
                 status: 201
               }
             }
    end

    test "return a multipart body for an upload" do
      example = Samples.APIModel.example(upload_request())

      assert Formatter.request_object(example) == %{
               body: %Multipart{
                 boundary: "---boundary",
                 parts: [
                   %{
                     content_type: "image/png",
                     filename: "screenshot.png",
                     name: "file",
                     value: "image-binary"
                   }
                 ]
               },
               content_type: "multipart/form-data",
               headers: %{},
               schema: %{},
               response: %{body: %{}, content_type: nil, headers: %{}, schema: %{}, status: nil}
             }
    end
  end

  describe "response_object/1" do
    test "return the response with its status, body and schema" do
      example = Samples.APIModel.example(users_create_request())

      assert Formatter.response_object(example) == %{
               status: 201,
               content_type: "application/json",
               headers: %{},
               body: %{"age" => 5, "name" => "teste"},
               schema: %{
                 type: "object",
                 properties: %{
                   "age" => %{example: 5, format: "int32", type: "number"},
                   "name" => %{example: "teste", type: "string"}
                 }
               }
             }
    end
  end

  describe "resource_parameters/1" do
    test "keep only the path parameters the resource uri carries" do
      operation =
        Samples.APIModel.operation(%Request{
          path_params: %{"users_id" => "1", "id" => 5},
          path: "/users/{users_id}/posts/{id}"
        })

      assert Formatter.resource_parameters(operation) == %{
               "usersId" => %{example: "1", type: "string", required: true}
             }
    end

    test "return no parameters when the request had none" do
      operation =
        Samples.APIModel.operation(%Request{path_params: %{}, path: "/users/{id}"})

      assert Formatter.resource_parameters(operation) == %{}
    end

    test "return no parameters when the path ends with its only parameter" do
      operation =
        Samples.APIModel.operation(%Request{path_params: %{"id" => 1}, path: "/posts/{id}"})

      assert Formatter.resource_parameters(operation) == %{}
    end
  end

  describe "action_parameters/1" do
    test "format every path parameter of the action" do
      operation =
        Samples.APIModel.operation(%Request{
          path_params: %{"users_id" => "1", "id" => 5},
          path: "/users/{users_id}/posts/{id}"
        })

      assert Formatter.action_parameters(operation) == %{
               "id" => %{example: 5, required: true, type: "number", format: "int32"},
               "usersId" => %{example: "1", required: true, type: "string"}
             }
    end

    test "return no parameters when the request had none" do
      assert Formatter.action_parameters(Samples.APIModel.operation(%Request{})) == %{}
    end
  end

  describe "action_query_parameters/1" do
    test "format every query parameter of the action" do
      operation = Samples.APIModel.operation(%Request{query_params: %{"user_age" => "15"}})

      assert Formatter.action_query_parameters(operation) == %{
               "user_age" => %{example: "15", type: "string"}
             }
    end

    test "return no parameters when the request had none" do
      assert Formatter.action_query_parameters(Samples.APIModel.operation(%Request{})) == %{}
    end
  end

  describe "response_schema/1" do
    test "return the schema of a json response" do
      example = Samples.APIModel.example(users_create_request())

      assert Formatter.response_schema(example) == %{
               type: "object",
               properties: %{
                 "age" => %{example: 5, format: "int32", type: "number"},
                 "name" => %{example: "teste", type: "string"}
               }
             }
    end

    test "return no schema for a plain text response" do
      example =
        Samples.APIModel.example(%Request{
          resource: "Users",
          resp_body: "success",
          resp_headers: [{"content-type", "text/plain; charset=utf-8"}]
        })

      assert Formatter.response_schema(example) == %{}
    end
  end

  describe "request_schema/1" do
    test "return the schema of a json request body" do
      example = Samples.APIModel.example(users_create_request())

      assert Formatter.request_schema(example) == %{
               type: "object",
               properties: %{
                 "age" => %{example: 5, format: "int32", type: "number"},
                 "name" => %{example: "teste", type: "string"}
               }
             }
    end

    test "return no schema for an empty body" do
      example =
        Samples.APIModel.example(%Request{
          header_params: [{"content-type", "application/json; boundary=plug_conn_test"}],
          request_body: %{}
        })

      assert Formatter.request_schema(example) == %{}
    end

    test "return no schema for an upload body" do
      assert Formatter.request_schema(Samples.APIModel.example(upload_request())) == %{}
    end

    test "use a schema name the consumer declared as the json schema title" do
      example =
        Samples.APIModel.example(
          RequestsGenerator.users_create(schema: "Users", req_schema: "createUsers")
        )

      assert %{title: "createUsers"} = Formatter.request_schema(example)
      assert %{title: "Users"} = Formatter.response_schema(example)
    end

    test "keep the schema anonymous when the consumer declared no name" do
      example = Samples.APIModel.example(RequestsGenerator.users_create())

      refute Map.has_key?(Formatter.request_schema(example), :title)
      refute Map.has_key?(Formatter.response_schema(example), :title)
    end
  end

  describe "request_body/1" do
    test "return a multipart body for an upload" do
      example =
        Samples.APIModel.example(%Request{
          header_params: [{"content-type", "multipart/form-data; boundary=---boundary"}],
          request_body: %{
            "user_id" => "123",
            "file" => %Upload{
              content_type: "image/png",
              filename: "screenshot.png",
              path: "/tmp/multipart-id"
            }
          }
        })

      assert Formatter.request_body(example) == %Multipart{
               boundary: "---boundary",
               parts: [
                 %{content_type: "text/plain", name: "user_id", value: "123"},
                 %{
                   content_type: "image/png",
                   filename: "screenshot.png",
                   name: "file",
                   value: "image-binary"
                 }
               ]
             }
    end

    test "return the body of a json request" do
      example = Samples.APIModel.example(users_create_request())

      assert Formatter.request_body(example) == %{"age" => 5, "name" => "teste"}
    end
  end

  describe "response_body/1" do
    test "return the decoded body of a json response" do
      example =
        Samples.APIModel.example(%Request{
          resource: "Users",
          resp_body: ~s({"id":1,"title":"user 1"}),
          resp_headers: [{"content-type", "application/json"}]
        })

      assert Formatter.response_body(example) == %{"id" => 1, "title" => "user 1"}
    end

    test "return an empty body when the response had none" do
      example =
        Samples.APIModel.example(%Request{
          resp_body: "",
          resp_headers: [{"cache-control", "max-age=0, private, must-revalidate"}]
        })

      assert Formatter.response_body(example) == %{}
    end

    test "return an empty body when the response carried no content type" do
      example =
        Samples.APIModel.example(%Request{resp_body: ~s({"id":1}), resp_headers: []})

      assert example.response_decode_error == :missing_content_type
      assert Formatter.response_body(example) == %{}
    end

    test "return the raw body when the content type could not be decoded" do
      example =
        Samples.APIModel.example(%Request{
          resp_body: "<html></html>",
          resp_headers: [{"content-type", "text/html"}]
        })

      assert example.response_decode_error == {:unknown_content_type, "text/html"}
      assert Formatter.response_body(example) == "<html></html>"
    end
  end

  describe "action_key/1" do
    test "return the verb and the path with camelized parameters" do
      operation =
        Samples.APIModel.operation(%Request{
          path: "/users/{users_id}/posts/{id}",
          verb: "post"
        })

      assert Formatter.action_key(operation) == "POST /users/{usersId}/posts/{id}"
    end
  end

  describe "action_name/1" do
    test "return the resource and the action" do
      operation =
        Samples.APIModel.operation(%Request{resource: "Users Posts", action: "show"})

      assert Formatter.action_name(operation) == "Users Posts show"
    end
  end

  describe "resource_key/1" do
    test "return the same key for the path with and without its last parameter" do
      one = Samples.APIModel.operation(%Request{path: "/users/{users_id}/posts/{id}"})
      two = Samples.APIModel.operation(%Request{path: "/users/{users_id}/posts"})

      assert Formatter.resource_key(one) == "/users/{usersId}/posts"
      assert Formatter.resource_key(two) == "/users/{usersId}/posts"
    end
  end

  defp users_posts_show_request do
    %Request{
      action: "show",
      controller: Xcribe.PostsController,
      description: "get all user posts",
      header_params: [
        {"authorization", "token"},
        {"content-type", "application/json; charset=utf-8"}
      ],
      path: "/users/{users_id}/posts/{id}",
      path_params: %{"users_id" => "1", "id" => "2"},
      query_params: %{"user_age" => "34"},
      request_body: %{},
      resource: "Users Posts",
      resp_body: ~s({"id":1,"title":"user 1"}),
      resp_headers: [
        {"content-type", "application/json; charset=utf-8"},
        {"cache-control", "max-age=0, private, must-revalidate"}
      ],
      status_code: 200,
      verb: "get"
    }
  end

  defp users_create_request do
    %Request{
      action: "create",
      resource: "Users",
      description: "create an user",
      header_params: [
        {"authorization", "token"},
        {"content-type", "application/json; charset=utf-8"}
      ],
      request_body: %{"age" => 5, "name" => "teste"},
      resp_body: ~s({"age":5,"name":"teste"}),
      resp_headers: [{"content-type", "application/json; charset=utf-8"}],
      status_code: 201
    }
  end

  defp upload_request do
    %Request{
      header_params: [{"content-type", "multipart/form-data; boundary=---boundary"}],
      request_body: %{
        "file" => %Upload{
          content_type: "image/png",
          filename: "screenshot.png",
          path: "/tmp/multipart-id"
        }
      }
    }
  end
end
