defmodule Xcribe.Swagger.FormatterTest do
  use ExUnit.Case, async: true

  alias Xcribe.Request
  alias Xcribe.Support.Information, as: ExampleInformation
  alias Xcribe.Support.Samples.SwaggerFormater, as: Samples
  alias Xcribe.Swagger.Formatter

  describe "raw_openapi_object/0" do
    test "return an empty OpenAPI object" do
      expected = %{
        openapi: "3.0.3",
        info: nil,
        servers: nil,
        paths: nil,
        components: nil
      }

      assert Formatter.raw_openapi_object() == expected
    end
  end

  describe "info_object/1" do
    test "return the info object by xcribe information" do
      api_info = ExampleInformation.api_info()

      assert Formatter.info_object(api_info) == %{
               title: api_info.name,
               description: api_info.description,
               version: "1"
             }
    end
  end

  describe "server_object/1" do
    test "return the server object by xcribe information" do
      api_info = ExampleInformation.api_info()

      assert Formatter.server_object(api_info) == [
               %{
                 url: api_info.host,
                 description: ""
               }
             ]
    end
  end

  describe "path_item_object_from_request/1" do
    test "return a basic struch with the path item and parameters from a request" do
      request = %Request{
        header_params: [
          {"authorization", "token"},
          {"content-type", "application/json; charset=utf-8"}
        ],
        path_params: %{},
        request_body: %{},
        resp_body: "[{\"id\":1,\"name\":\"user 1\"},{\"id\":2,\"name\":\"user 2\"}]",
        resp_headers: [
          {"content-type", "application/json; charset=utf-8"},
          {"cache-control", "max-age=0, private, must-revalidate"}
        ],
        status_code: 200,
        verb: "get",
        params: %{
          "fields" => %{"articles" => "title,body", "people" => "name"},
          "include" => "author"
        },
        query_params: %{
          "fields" => %{"articles" => "title,body", "people" => "name"},
          "include" => "author"
        }
      }

      expected = %{
        "get" => %{
          description: "",
          summary: "",
          parameters: [
            %{
              name: "fields",
              in: "query",
              schema: %{
                properties: %{"articles" => %{type: "string"}, "people" => %{type: "string"}},
                type: "object"
              },
              example: %{"articles" => "title,body", "people" => "name"}
            },
            %{name: "include", in: "query", schema: %{type: "string"}, example: "author"}
          ],
          security: [%{"api_key" => []}],
          responses: %{
            200 => %{
              description: "",
              headers: %{"cache-control" => %{description: "", schema: %{type: "string"}}},
              content: %{
                "application/json" => %{
                  schema: %{
                    type: "array",
                    items: %{
                      type: "object",
                      properties: %{
                        "id" => %{format: "int32", type: "number"},
                        "name" => %{type: "string"}
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }

      assert Formatter.path_item_object_from_request(request) == expected
    end

    test "with request body" do
      request = %Request{
        header_params: [{"content-type", "application/json; charset=utf-8"}],
        path_params: %{},
        request_body: %{"name" => "Jonny"},
        resp_body: "{\"name\":\"user 1\"}",
        resp_headers: [{"content-type", "application/json; charset=utf-8"}],
        status_code: 201,
        verb: "post",
        params: %{},
        query_params: %{}
      }

      expected = %{
        "post" => %{
          summary: "",
          description: "",
          parameters: [],
          requestBody: %{
            description: "",
            content: %{
              "application/json" => %{
                schema: %{properties: %{"name" => %{type: "string"}}, type: "object"}
              }
            }
          },
          security: [],
          responses: %{
            201 => %{
              description: "",
              headers: %{},
              content: %{
                "application/json" => %{
                  schema: %{properties: %{"name" => %{type: "string"}}, type: "object"}
                }
              }
            }
          }
        }
      }

      assert Formatter.path_item_object_from_request(request) == expected
    end
  end

  describe "response_object_from_request/1" do
    test "return a response object" do
      request = %Request{
        resp_body: "[{\"id\":1,\"name\":\"user 1\"},{\"id\":2,\"name\":\"user 2\"}]",
        resp_headers: [
          {"content-type", "application/json; charset=utf-8"},
          {"cache-control", "max-age=0, private, must-revalidate"}
        ]
      }

      expected = %{
        description: "",
        headers: %{"cache-control" => %{description: "", schema: %{type: "string"}}},
        content: %{
          "application/json" => %{
            schema: %{
              type: "array",
              items: %{
                type: "object",
                properties: %{
                  "id" => %{type: "number", format: "int32"},
                  "name" => %{type: "string"}
                }
              }
            }
          }
        }
      }

      assert Formatter.response_object_from_request(request) == expected
    end

    test "when has a 204 with no content" do
      request = %Request{
        resp_body: "",
        resp_headers: [
          {"content-type", "application/json; charset=utf-8"},
          {"cache-control", "max-age=0, private, must-revalidate"}
        ]
      }

      expected = %{
        description: "",
        headers: %{"cache-control" => %{description: "", schema: %{type: "string"}}}
      }

      assert Formatter.response_object_from_request(request) == expected
    end
  end

  describe "request_body_object_from_request/1" do
    test "return a request body " do
      request = %Request{
        header_params: [{"content-type", "application/json; boundary=plug_conn_test"}],
        request_body: %{"authentication" => %{"login" => "userlogin"}, "name" => "some name"}
      }

      expected = %{
        description: "",
        content: %{
          "application/json" => %{
            schema: %{
              type: "object",
              properties: %{
                "name" => %{type: "string"},
                "authentication" => %{type: "object", properties: %{"login" => %{type: "string"}}}
              }
            }
          }
        }
      }

      assert Formatter.request_body_object_from_request(request) == expected
    end
  end

  describe "security_requirement_object_by_request/1" do
    test "return security for given request" do
      request_bearer = %Request{header_params: [{"authorization", "Bearer jwt"}]}
      request_basic = %Request{header_params: [{"authorization", "Basic base"}]}
      request_api_key = %Request{header_params: [{"authorization", "key"}]}
      request_no_auth = %Request{header_params: []}

      assert Formatter.security_requirement_object_by_request(request_no_auth) == []
      assert Formatter.security_requirement_object_by_request(request_basic) == [%{"basic" => []}]

      assert Formatter.security_requirement_object_by_request(request_bearer) == [
               %{"bearer" => []}
             ]

      assert Formatter.security_requirement_object_by_request(request_api_key) == [
               %{
                 "api_key" => []
               }
             ]
    end
  end

  describe "security_scheme_object_from_request/1" do
    test "return security for jwt token" do
      request_bearer = %Request{header_params: [{"authorization", "Bearer jwt"}]}

      expected = %{
        "bearer" => %{
          type: "http",
          scheme: "bearer",
          bearerFormat: "JWT"
        }
      }

      assert Formatter.security_scheme_object_from_request(request_bearer) == expected
    end

    test "return the security scheme for basic authentication" do
      request_basic = %Request{header_params: [{"authorization", "Basic base"}]}

      expected = %{
        "basic" => %{
          type: "http",
          scheme: "basic"
        }
      }

      assert Formatter.security_scheme_object_from_request(request_basic) == expected
    end

    test "return the security scheme for api key authentication" do
      request_api_key = %Request{header_params: [{"authorization", "key"}]}

      expected = %{
        "api_key" => %{
          "type" => "apiKey",
          "name" => "authorization",
          "in" => "header"
        }
      }

      assert Formatter.security_scheme_object_from_request(request_api_key) == expected
    end

    test "return empy map when cant identify the security scheme" do
      request_no_auth = %Request{header_params: []}

      assert Formatter.security_scheme_object_from_request(request_no_auth) == %{}
    end
  end

  describe "parameter_objects_from_request/1" do
    test "return all parameters from a request" do
      request = %Request{
        header_params: [{"custom-header-param", "header value"}],
        path_params: %{"id" => 6, "users_id" => "1"},
        query_params: %{
          "fields" => %{"articles" => "title,body", "people" => "name"},
          "include" => "author",
          "users" => ["bar", "qux"]
        }
      }

      expected = [
        %{
          name: "id",
          in: "path",
          required: true,
          schema: %{type: "number", format: "int32"},
          example: 6
        },
        %{name: "users_id", in: "path", required: true, schema: %{type: "string"}, example: "1"},
        %{
          name: "custom-header-param",
          in: "header",
          schema: %{type: "string"},
          example: "header value"
        },
        %{
          name: "fields",
          in: "query",
          schema: %{
            type: "object",
            properties: %{"articles" => %{type: "string"}, "people" => %{type: "string"}}
          },
          example: %{"articles" => "title,body", "people" => "name"}
        },
        %{name: "include", in: "query", schema: %{type: "string"}, example: "author"},
        %{
          name: "users",
          in: "query",
          schema: %{type: "array", items: %{type: "string"}},
          example: ["bar", "qux"]
        }
      ]

      assert Formatter.parameter_objects_from_request(request) == expected
    end

    test "ignore header params authorization, accept and content-type" do
      request = %Request{
        header_params: [
          {"custom-header-param", "header value"},
          {"content-type", "header value"},
          {"authorization", "header value"},
          {"accept", "header value"}
        ],
        path_params: %{},
        query_params: %{}
      }

      expected = [
        %{
          name: "custom-header-param",
          in: "header",
          schema: %{type: "string"},
          example: "header value"
        }
      ]

      assert Formatter.parameter_objects_from_request(request) == expected
    end
  end

  describe "schema_object_for/1" do
    test "return a schema given data" do
      assert Formatter.schema_object_for({"alias", "Jon"}) == %{
               title: "alias",
               type: "string"
             }

      assert Formatter.schema_object_for({"age", 5}) == %{
               title: "age",
               type: "number",
               format: "int32"
             }

      assert Formatter.schema_object_for({"percent", 5.8}) == %{
               title: "percent",
               type: "number",
               format: "float"
             }
    end

    test "given opt title false not return title key" do
      opt = [title: false]

      assert Formatter.schema_object_for({"name", "value"}, opt) == %{type: "string"}
      assert Formatter.schema_object_for({"name", 1}, opt) == %{type: "number", format: "int32"}
      assert Formatter.schema_object_for({"name", 1.2}, opt) == %{type: "number", format: "float"}
    end

    test "given opt example true return the example" do
      opt = [title: false, example: true]

      assert Formatter.schema_object_for({"name", "value"}, opt) == %{
               type: "string",
               example: "value"
             }

      assert Formatter.schema_object_for({"name", 1}, opt) == %{
               type: "number",
               format: "int32",
               example: 1
             }

      assert Formatter.schema_object_for({"name", 1.2}, opt) == %{
               type: "number",
               format: "float",
               example: 1.2
             }
    end

    test "return an schema of a map with properties" do
      data = {"user", %{"id" => 1, "name" => "Jonny"}}

      expected = %{
        title: "user",
        type: "object",
        properties: %{
          "id" => %{
            type: "number",
            format: "int32"
          },
          "name" => %{
            type: "string"
          }
        }
      }

      assert Formatter.schema_object_for(data) == expected
    end

    test "schema for nested map" do
      data =
        {"data",
         %{
           "id" => 1,
           "attributes" => %{"name" => "Jonny"},
           "relationships" => %{
             "posts" => %{"id" => 5, "attributes" => %{"title" => "cool post"}}
           }
         }}

      expected = %{
        title: "data",
        type: "object",
        properties: %{
          "attributes" => %{type: "object", properties: %{"name" => %{type: "string"}}},
          "id" => %{type: "number", format: "int32"},
          "relationships" => %{
            type: "object",
            properties: %{
              "posts" => %{
                type: "object",
                properties: %{
                  "attributes" => %{type: "object", properties: %{"title" => %{type: "string"}}},
                  "id" => %{type: "number", format: "int32"}
                }
              }
            }
          }
        }
      }

      assert Formatter.schema_object_for(data) == expected
    end

    test "schema for a list (array)" do
      data = {"users", ["Doug", "Jonny"]}

      expected = %{
        title: "users",
        type: "array",
        items: %{type: "string"}
      }

      assert Formatter.schema_object_for(data) == expected
    end

    test "schema for a list (array) of maps" do
      data =
        {"data",
         [
           %{"id" => 1, "attributes" => %{"name" => "Jonny"}},
           %{"id" => 2, "attributes" => %{"name" => "Doug"}}
         ]}

      expected = %{
        title: "data",
        type: "array",
        items: %{
          type: "object",
          properties: %{
            "attributes" => %{type: "object", properties: %{"name" => %{type: "string"}}},
            "id" => %{type: "number", format: "int32"}
          }
        }
      }

      assert Formatter.schema_object_for(data) == expected
    end

    test "schema for a map with an empty list" do
      data =
        {"data",
         [
           %{"id" => 1, "attributes" => %{"name" => "Jonny", "likes" => []}},
           %{"id" => 2, "attributes" => %{"name" => "Doug", "likes" => []}}
         ]}

      expected = %{
        title: "data",
        type: "array",
        items: %{
          type: "object",
          properties: %{
            "attributes" => %{
              type: "object",
              properties: %{
                "name" => %{type: "string"},
                "likes" => %{type: "array", items: %{type: "string"}}
              }
            },
            "id" => %{type: "number", format: "int32"}
          }
        }
      }

      assert Formatter.schema_object_for(data) == expected
    end
  end

  describe "merge_parameter_object_lists/2" do
    test "keep uniq names and " do
      base_list = [
        %{name: "id", in: "path", required: true, schema: %{type: "string"}, example: 6},
        %{name: "id", in: "header", schema: %{type: "string"}, example: "8"}
      ]

      new_list = [
        %{name: "id", in: "path", required: true, schema: %{type: "string"}, example: 9},
        %{name: "id", in: "query", schema: %{type: "string"}, example: "9090"},
        %{name: "alias", in: "query", schema: %{type: "string"}, example: "jon"}
      ]

      expected = [
        %{name: "alias", in: "query", schema: %{type: "string"}, example: "jon"},
        %{name: "id", in: "query", schema: %{type: "string"}, example: "9090"},
        %{name: "id", in: "path", required: true, schema: %{type: "string"}, example: 6},
        %{name: "id", in: "header", schema: %{type: "string"}, example: "8"}
      ]

      assert Formatter.merge_parameter_object_lists(base_list, new_list) == expected
    end
  end

  describe "merge_path_item_objects/3" do
    test "merge 2 object with diferente responses" do
      object_one = Samples.path_item_object_without_request_body()
      object_two = Samples.path_item_object_with_request_body()
      expected = Samples.expected_path_objects_merge()

      assert Formatter.merge_path_item_objects(object_one, object_two, "put") == expected
    end
  end
end
