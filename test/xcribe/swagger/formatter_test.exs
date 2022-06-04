defmodule Xcribe.Swagger.FormatterTest do
  use ExUnit.Case, async: true

  alias Plug.Upload
  alias Xcribe.Request
  alias Xcribe.Specification
  alias Xcribe.Swagger.Formatter

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

  describe "request_objects/1" do
    test "request as a fully openapi path specification" do
      config = %{specification_source: "test/support/.xcribe.exs", json_library: Jason}
      spec = Specification.api_specification(config)

      request = %Request{
        path: "/users",
        header_params: [
          {"authorization", "token"},
          {"content-type", "application/json; charset=utf-8"}
        ],
        description: "Get users",
        groups_tags: ["Users"],
        path_params: %{},
        request_body: %{},
        resp_body: "[{\"id\":1,\"name\":\"user 1\"},{\"id\":2,\"name\":\"user 2\"}]",
        resp_headers: [
          {"content-type", "application/json; charset=utf-8"},
          {"cache-control", "max-age=0, private, must-revalidate"}
        ],
        status_code: 200,
        verb: "get",
        resource: "Users",
        params: %{
          "fields" => %{"articles" => "title,body", "people" => "name"},
          "include" => "author"
        },
        query_params: %{
          "fields" => %{"articles" => "title,body", "people" => "name"},
          "include" => "author"
        }
      }

      path = %{
        "/users" => %{
          "get" => %{
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
            security: [%{"api_key" => []}],
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
        }
      }

      schemas = %{
        "Users" => %{
          type: "object",
          properties: %{
            "id" => %{format: "int32", type: "number", example: 1},
            "name" => %{type: "string", example: "user 1"}
          }
        }
      }

      security = %{
        "api_key" => %{"in" => "header", "name" => "authorization", "type" => "apiKey"}
      }

      assert Formatter.request_objects(request, spec, config) == %{
               path: path,
               schemas: schemas,
               security: security
             }
    end

    test "with request body" do
      config = %{specification_source: "test/support/.xcribe.exs", json_library: Jason}
      spec = Specification.api_specification(config)

      request = %Request{
        path: "/users",
        description: "",
        header_params: [{"content-type", "application/json; charset=utf-8"}],
        groups_tags: ["Users"],
        path_params: %{},
        request_body: %{"name" => "Jonny"},
        resp_body: "{\"name\":\"user 1\"}",
        resp_headers: [{"content-type", "application/json; charset=utf-8"}],
        status_code: 201,
        verb: "post",
        resource: "Users",
        params: %{},
        query_params: %{}
      }

      schemas = %{
        "postUsers" => %{
          type: "object",
          properties: %{"name" => %{type: "string", example: "Jonny"}}
        },
        "Users" => %{
          type: "object",
          properties: %{"name" => %{type: "string", example: "user 1"}}
        }
      }

      path = %{
        "/users" => %{
          "post" => %{
            description: "",
            parameters: [],
            security: [],
            tags: ["Users"],
            requestBody: %{
              content: %{
                "application/json" => %{schema: %{"$ref" => "#/components/schemas/postUsers"}}
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
        }
      }

      security = %{}

      assert Formatter.request_objects(request, spec, config) == %{
               path: path,
               schemas: schemas,
               security: security
             }
    end

    test "when has a 204 with no content" do
      config = %{specification_source: "test/support/.xcribe.exs", json_library: Jason}
      spec = Specification.api_specification(config)

      request = %Request{
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

      schemas = %{}
      security = %{}

      path = %{
        "/users/{id}" => %{
          "delete" => %{
            description: "",
            parameters: [%{example: "1", in: "query", name: "id", schema: %{type: "string"}}],
            responses: %{
              204 => %{
                description: "",
                headers: %{"cache-control" => %{schema: %{type: "string"}}}
              }
            },
            security: [],
            tags: []
          }
        }
      }

      assert Formatter.request_objects(request, spec, config) == %{
               path: path,
               schemas: schemas,
               security: security
             }
    end

    test "with upload body" do
      config = %{specification_source: "test/support/.xcribe.exs", json_library: Jason}
      spec = Specification.api_specification(config)

      request = %Request{
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
        resp_body: "{\"name\":\"user 1\"}",
        resp_headers: [{"content-type", "application/json; charset=utf-8"}],
        verb: "put",
        resource: "Users"
      }

      security = %{}

      path = %{
        "/users" => %{
          "put" => %{
            description: "",
            parameters: [],
            requestBody: %{
              content: %{
                "multipart/form-data" => %{schema: %{"$ref" => "#/components/schemas/putUsers"}}
              }
            },
            responses: %{
              200 => %{
                description: "",
                content: %{
                  "application/json" => %{schema: %{"$ref" => "#/components/schemas/Users"}}
                },
                headers: %{}
              }
            },
            security: [],
            tags: ["Users"]
          }
        }
      }

      schemas = %{
        "Users" => %{
          properties: %{"name" => %{example: "user 1", type: "string"}},
          type: "object"
        },
        "putUsers" => %{
          properties: %{
            "file" => %{format: "binary", type: "string"},
            "user_id" => %{example: "123", type: "string"}
          },
          type: "object"
        }
      }

      assert Formatter.request_objects(request, spec, config) == %{
               path: path,
               schemas: schemas,
               security: security
             }
    end
  end
end
