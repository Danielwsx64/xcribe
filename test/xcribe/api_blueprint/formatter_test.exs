defmodule Xcribe.ApiBlueprint.FormatterTest do
  use ExUnit.Case, async: true

  alias Plug.Upload
  alias Xcribe.ApiBlueprint.{Formatter, Multipart}
  alias Xcribe.Request
  alias Xcribe.Support.RequestsGenerator

  setup do
    {:ok, %{config: %{json_library: Jason}}}
  end

  describe "put_object_into_groups/2" do
    test "add request object", %{config: config} do
      request = put_in(RequestsGenerator.users_index().__meta__, %{config: config})

      [group_name] = request.groups_tags

      request_object = Formatter.full_request_object(request)

      assert Formatter.put_object_into_groups(%{}, request_object) == %{
               group_name => request_object
             }
    end

    test "request with multiple groups", %{config: config} do
      groups_tags = ["Users", "Public API"]

      request =
        put_in(RequestsGenerator.users_index(groups_tags: groups_tags).__meta__, %{config: config})

      request_object = Formatter.full_request_object(request)

      assert Formatter.put_object_into_groups(%{}, request_object) == %{
               "Users" => request_object,
               "Public API" => request_object
             }
    end

    test "same request twice merge data", %{config: config} do
      base_request = put_in(RequestsGenerator.users_index().__meta__, %{config: config})

      request_one = %{
        base_request
        | description: "Cool description",
          query_params: %{"user_age" => "32"}
      }

      request_two = %{
        base_request
        | description: "Other description",
          query_params: %{"limit" => "5"}
      }

      [group_name] = base_request.groups_tags

      full_request_one = Formatter.full_request_object(request_one)
      full_request_two = Formatter.full_request_object(request_two)

      assert %{}
             |> Formatter.put_object_into_groups(full_request_one)
             |> Formatter.put_object_into_groups(full_request_two) == %{
               group_name => %{
                 summary: "",
                 groups: ["Users"],
                 description: "",
                 resources: %{
                   "/users" => %{
                     name: "Users",
                     description: "",
                     summary: "",
                     parameters: %{},
                     actions: %{
                       "GET /users" => %{
                         name: "Users index",
                         description: "",
                         summary: "",
                         parameters: %{},
                         query_parameters: %{
                           "limit" => %{example: "5", type: "string"},
                           "user_age" => %{example: "32", type: "string"}
                         },
                         requests: %{
                           "Cool description" => %{
                             content_type: "application/json",
                             headers: %{},
                             body: %{},
                             schema: %{},
                             response: %{
                               status: 200,
                               content_type: "application/json",
                               headers: %{
                                 "cache-control" => "max-age=0, private, must-revalidate"
                               },
                               body: [
                                 %{"id" => 1, "name" => "user 1"},
                                 %{"id" => 2, "name" => "user 2"}
                               ],
                               schema: %{
                                 type: "array",
                                 items: %{
                                   type: "object",
                                   properties: %{
                                     "id" => %{example: 1, format: "int32", type: "number"},
                                     "name" => %{example: "user 1", type: "string"}
                                   }
                                 }
                               }
                             }
                           },
                           "Other description" => %{
                             body: %{},
                             schema: %{},
                             content_type: "application/json",
                             headers: %{},
                             response: %{
                               status: 200,
                               content_type: "application/json",
                               headers: %{
                                 "cache-control" => "max-age=0, private, must-revalidate"
                               },
                               body: [
                                 %{"id" => 1, "name" => "user 1"},
                                 %{"id" => 2, "name" => "user 2"}
                               ],
                               schema: %{
                                 type: "array",
                                 items: %{
                                   type: "object",
                                   properties: %{
                                     "id" => %{example: 1, format: "int32", type: "number"},
                                     "name" => %{example: "user 1", type: "string"}
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
             }
    end
  end

  describe "full_request_object/1" do
    test "return group object", %{config: config} do
      struct = %Request{
        __meta__: %{config: config},
        action: "show",
        controller: Elixir.Xcribe.PostsController,
        description: "get all user posts",
        header_params: [{"content-type", "application/json"}],
        groups_tags: ["Users"],
        params: %{},
        path: "/users",
        path_params: %{},
        query_params: %{},
        request_body: %{},
        resource: "Users",
        resp_body: "{\"id\":1,\"title\":\"user 1\"}",
        resp_headers: [{"content-type", "application/json"}],
        status_code: 200,
        verb: "get"
      }

      assert Formatter.full_request_object(struct) == %{
               groups: ["Users"],
               description: "",
               summary: "",
               resources: %{
                 "/users" => %{
                   name: "Users",
                   description: "",
                   summary: "",
                   parameters: %{},
                   actions: %{
                     "GET /users" => %{
                       name: "Users show",
                       description: "",
                       summary: "",
                       parameters: %{},
                       query_parameters: %{},
                       requests: %{
                         "get all user posts" => %{
                           content_type: "application/json",
                           headers: %{},
                           body: %{},
                           schema: %{},
                           response: %{
                             status: 200,
                             content_type: "application/json",
                             headers: %{},
                             body: %{"id" => 1, "title" => "user 1"},
                             schema: %{
                               type: "object",
                               properties: %{
                                 "id" => %{example: 1, format: "int32", type: "number"},
                                 "title" => %{example: "user 1", type: "string"}
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
    end
  end

  describe "resource_object/1" do
    test "return resource object", %{config: config} do
      struct = %Request{
        __meta__: %{config: config},
        action: "show",
        controller: Elixir.Xcribe.PostsController,
        description: "get all user posts",
        header_params: [
          {"authorization", "token"},
          {"content-type", "application/json; charset=utf-8"}
        ],
        params: %{"users_id" => "1"},
        path: "/users/{users_id}/posts/{id}",
        path_params: %{"users_id" => "1", "id" => "2"},
        query_params: %{"user_age" => "34"},
        request_body: %{},
        resource: "Users Posts",
        resp_body: "{\"id\":1,\"title\":\"user 1\"}",
        resp_headers: [
          {"content-type", "application/json; charset=utf-8"},
          {"cache-control", "max-age=0, private, must-revalidate"}
        ],
        status_code: 200,
        verb: "get"
      }

      assert Formatter.resource_object(struct) == %{
               "/users/{usersId}/posts" => %{
                 name: "Users Posts",
                 description: "",
                 summary: "",
                 parameters: %{"usersId" => %{example: "1", required: true, type: "string"}},
                 actions: %{
                   "GET /users/{usersId}/posts/{id}" => %{
                     name: "Users Posts show",
                     description: "",
                     summary: "",
                     parameters: %{
                       "id" => %{example: "2", required: true, type: "string"},
                       "usersId" => %{example: "1", required: true, type: "string"}
                     },
                     query_parameters: %{"user_age" => %{example: "34", type: "string"}},
                     requests: %{
                       "get all user posts" => %{
                         content_type: "application/json",
                         headers: %{"authorization" => "token"},
                         body: %{},
                         schema: %{},
                         response: %{
                           status: 200,
                           content_type: "application/json",
                           headers: %{"cache-control" => "max-age=0, private, must-revalidate"},
                           body: %{"id" => 1, "title" => "user 1"},
                           schema: %{
                             type: "object",
                             properties: %{
                               "id" => %{example: 1, format: "int32", type: "number"},
                               "title" => %{example: "user 1", type: "string"}
                             }
                           }
                         }
                       }
                     }
                   }
                 }
               }
             }
    end
  end

  describe "action_object/1" do
    test "return full action object", %{config: config} do
      struct = %Request{
        __meta__: %{config: config},
        action: "show",
        controller: Elixir.Xcribe.PostsController,
        description: "get all user posts",
        header_params: [
          {"authorization", "token"},
          {"content-type", "application/json; charset=utf-8"}
        ],
        params: %{"users_id" => "1"},
        path: "/users/{users_id}/posts/{id}",
        path_params: %{"users_id" => "1", "id" => "2"},
        query_params: %{"user_age" => "16"},
        request_body: %{},
        resource: "Users Posts",
        resp_body: "{\"id\":1,\"title\":\"user 1\"}",
        resp_headers: [
          {"content-type", "application/json; charset=utf-8"},
          {"cache-control", "max-age=0, private, must-revalidate"}
        ],
        status_code: 200,
        verb: "get"
      }

      assert Formatter.action_object(struct) == %{
               "GET /users/{usersId}/posts/{id}" => %{
                 name: "Users Posts show",
                 description: "",
                 summary: "",
                 parameters: %{
                   "id" => %{example: "2", required: true, type: "string"},
                   "usersId" => %{example: "1", required: true, type: "string"}
                 },
                 query_parameters: %{"user_age" => %{example: "16", type: "string"}},
                 requests: %{
                   "get all user posts" => %{
                     content_type: "application/json",
                     headers: %{"authorization" => "token"},
                     body: %{},
                     schema: %{},
                     response: %{
                       content_type: "application/json",
                       status: 200,
                       headers: %{"cache-control" => "max-age=0, private, must-revalidate"},
                       body: %{"id" => 1, "title" => "user 1"},
                       schema: %{
                         type: "object",
                         properties: %{
                           "id" => %{example: 1, format: "int32", type: "number"},
                           "title" => %{example: "user 1", type: "string"}
                         }
                       }
                     }
                   }
                 }
               }
             }
    end
  end

  describe "request_object/1" do
    test "return full request object", %{config: config} do
      struct = %Request{
        __meta__: %{config: config},
        description: "create an user",
        header_params: [
          {"authorization", "token"},
          {"content-type", "application/json; charset=utf-8"}
        ],
        request_body: %{"age" => 5, "name" => "teste"},
        resp_body: "{\"age\":5,\"name\":\"teste\"}",
        resp_headers: [{"content-type", "application/json; charset=utf-8"}],
        status_code: 201
      }

      assert Formatter.request_object(struct) == %{
               "create an user" => %{
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
             }
    end

    test "with a Upload struct in body", %{config: config} do
      request = %Request{
        __meta__: %{config: config},
        header_params: [{"content-type", "multipart/form-data; boundary=---boundary"}],
        request_body: %{
          "file" => %Upload{
            content_type: "image/png",
            filename: "screenshot.png",
            path: "/tmp/multipart-id"
          }
        }
      }

      expected = %{
        nil: %{
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
          response: %{body: %{}, content_type: nil, headers: %{}, schema: %{}, status: nil},
          schema: %{}
        }
      }

      assert Formatter.request_object(request) == expected
    end
  end

  describe "response_object/1" do
    test "return full response object", %{config: config} do
      struct = %Request{
        __meta__: %{config: config},
        resp_body: "{\"age\":5,\"name\":\"teste\"}",
        resp_headers: [{"content-type", "application/json; charset=utf-8"}],
        status_code: 201
      }

      assert Formatter.response_object(struct) == %{
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
    test "format resource URI parameters", %{config: config} do
      struct = %Request{
        __meta__: %{config: config},
        path_params: %{"users_id" => "1", "id" => 5},
        path: "/users/{users_id}/posts/{id}"
      }

      assert Formatter.resource_parameters(struct) == %{
               "usersId" => %{
                 example: "1",
                 type: "string",
                 required: true
               }
             }
    end

    test "no path paramters", %{config: config} do
      struct = %Request{
        __meta__: %{config: config},
        path_params: %{},
        path: "/users/{id}"
      }

      assert Formatter.resource_parameters(struct) == %{}
    end

    test "with endind param" do
      struct = %Request{
        path_params: %{"id" => 1},
        path: "/posts/{id}"
      }

      assert Formatter.resource_parameters(struct) == %{}
    end
  end

  describe "action_parameters/1" do
    test "format action URI parameters" do
      struct = %Request{
        path_params: %{"users_id" => "1", "id" => 5},
        path: "/users/{users_id}/posts/{id}"
      }

      assert Formatter.action_parameters(struct) == %{
               "id" => %{example: 5, required: true, type: "number", format: "int32"},
               "usersId" => %{example: "1", required: true, type: "string"}
             }
    end

    test "with no parameters" do
      struct = %Request{path_params: %{}}

      assert Formatter.action_parameters(struct) == %{}
    end
  end

  describe "action_query_parameters/1" do
    test "format action URI query parameters" do
      struct = %Request{query_params: %{"user_age" => "15"}}

      assert Formatter.action_query_parameters(struct) == %{
               "user_age" => %{example: "15", type: "string"}
             }
    end

    test "with no parameters" do
      struct = %Request{query_params: %{}}

      assert Formatter.action_query_parameters(struct) == %{}
    end
  end

  describe "response_schema/1" do
    test "return response schema for json content", %{config: config} do
      struct = %Request{
        __meta__: %{config: config},
        resp_body: "{\"age\":5,\"name\":\"teste\"}",
        resp_headers: [{"content-type", "application/json; charset=utf-8"}]
      }

      assert Formatter.response_schema(struct) == %{
               type: "object",
               properties: %{
                 "age" => %{example: 5, format: "int32", type: "number"},
                 "name" => %{example: "teste", type: "string"}
               }
             }
    end

    test "return schema for text/plain", %{config: config} do
      struct = %Request{
        __meta__: %{config: config},
        resp_body: "success",
        resp_headers: [{"content-type", "text/plain; charset=utf-8"}]
      }

      assert Formatter.response_schema(struct) == %{}
    end
  end

  describe "request_schema/1" do
    test "return request schema for json content" do
      struct = %Request{
        header_params: [
          {"authorization", "token"},
          {"content-type", "application/json; boundary=plug_conn_test"}
        ],
        request_body: %{"age" => 5, "name" => "teste"}
      }

      assert Formatter.request_schema(struct) == %{
               type: "object",
               properties: %{
                 "age" => %{example: 5, format: "int32", type: "number"},
                 "name" => %{example: "teste", type: "string"}
               }
             }
    end

    test "for empty body" do
      struct = %Request{
        header_params: [{"content-type", "application/json; boundary=plug_conn_test"}],
        request_body: %{}
      }

      assert Formatter.request_schema(struct) == %{}
    end

    test "with upload body" do
      request = %Request{
        header_params: [{"content-type", "multipart/form-data; boundary=---boundary"}],
        request_body: %{
          "user_id" => "123",
          "file" => %Upload{
            content_type: "image/png",
            filename: "screenshot.png",
            path: "/tmp/multipart-id"
          }
        }
      }

      assert Formatter.request_schema(request) == %{}
    end

    test "return schema for text/plain" do
      struct = %Request{request_body: %{}}

      assert Formatter.request_schema(struct) == %{}
    end
  end

  describe "test group subject" do
    test "with upload body" do
      request = %Request{
        header_params: [{"content-type", "multipart/form-data; boundary=---boundary"}],
        request_body: %{
          "user_id" => "123",
          "file" => %Upload{
            content_type: "image/png",
            filename: "screenshot.png",
            path: "/tmp/multipart-id"
          }
        }
      }

      expected = %Multipart{
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

      assert Formatter.request_body(request) == expected
    end

    test "return request body for json content" do
      struct = %Request{
        header_params: [
          {"authorization", "token"},
          {"content-type", "application/json; boundary=plug_conn_test"}
        ],
        request_body: %{"age" => 5, "name" => "teste"}
      }

      assert Formatter.request_body(struct) == struct.request_body
    end
  end

  describe "action_key/1" do
    test "return formatted action key" do
      struct = %Request{path: "/users/{users_id}/posts/{id}", verb: "post"}

      assert Formatter.action_key(struct) == "POST /users/{usersId}/posts/{id}"
    end
  end

  describe "action_name/1" do
    test "return formatted action name" do
      struct = %Request{
        resource: "Users Posts",
        action: "show"
      }

      assert Formatter.action_name(struct) == "Users Posts show"
    end
  end

  describe "resource_key/1" do
    test "return formatted resource key" do
      struct_one = %Request{path: "/users/{users_id}/posts/{id}"}
      struct_two = %Request{path: "/users/{users_id}/posts"}

      assert Formatter.resource_key(struct_one) == "/users/{usersId}/posts"
      assert Formatter.resource_key(struct_two) == "/users/{usersId}/posts"
    end
  end

  describe "response_body/1" do
    test "return response body", %{config: config} do
      struct = %Request{
        __meta__: %{config: config},
        resp_body: "{\"id\":1,\"title\":\"user 1\"}",
        resp_headers: [{"content-type", "application/json"}]
      }

      assert Formatter.response_body(struct) == %{"id" => 1, "title" => "user 1"}
    end

    test "response without content type", %{config: config} do
      struct = %Request{
        __meta__: %{config: config},
        resp_body: "",
        resp_headers: [{"cache-control", "max-age=0, private, must-revalidate"}]
      }

      assert Formatter.response_body(struct) == %{}
    end
  end
end
