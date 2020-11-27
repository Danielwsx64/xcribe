defmodule Xcribe.Swagger.FormatterTest do
  use ExUnit.Case, async: true

  alias Plug.Upload
  alias Xcribe.Request
  alias Xcribe.Support.Information, as: ExampleInformation
  alias Xcribe.Support.Samples.SwaggerFormater.PathItemObject, as: Samples
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
        resource: "users",
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
          summary: "",
          tags: ["users"],
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
                        "id" => %{format: "int32", type: "number", example: 1},
                        "name" => %{type: "string", example: "user 1"}
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
        resource: "users",
        params: %{},
        query_params: %{}
      }

      expected = %{
        "post" => %{
          description: "",
          parameters: [],
          security: [],
          summary: "",
          tags: ["users"],
          requestBody: %{
            description: "",
            content: %{
              "application/json" => %{
                schema: %{
                  type: "object",
                  properties: %{"name" => %{type: "string", example: "Jonny"}}
                }
              }
            }
          },
          responses: %{
            201 => %{
              description: "",
              headers: %{},
              content: %{
                "application/json" => %{
                  schema: %{
                    type: "object",
                    properties: %{"name" => %{type: "string", example: "user 1"}}
                  }
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
                  "id" => %{format: "int32", type: "number", example: 1},
                  "name" => %{type: "string", example: "user 1"}
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
                "authentication" => %{
                  type: "object",
                  properties: %{"login" => %{type: "string", example: "userlogin"}}
                },
                "name" => %{type: "string", example: "some name"}
              }
            }
          }
        }
      }

      assert Formatter.request_body_object_from_request(request) == expected
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

      expected = %{
        description: "",
        content: %{
          "multipart/form" => %{
            schema: %{
              type: "object",
              properties: %{
                "file" => %{format: "binary", type: "string"},
                "user_id" => %{example: "123", type: "string"}
              }
            },
            encoding: %{"file" => %{contentType: "image/png"}}
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

  describe "merge_parameter_object_lists/2" do
    test "keep uniq names and order by name" do
      parameters = [
        %{name: "id", in: "path", required: true, schema: %{type: "string"}, example: 6},
        %{name: "id", in: "header", schema: %{type: "string"}, example: "8"}
      ]

      new_params = [
        %{name: "id", in: "path", required: true, schema: %{type: "string"}, example: 9},
        %{name: "alias", in: "query", schema: %{type: "string"}, example: "jon"},
        %{name: "id", in: "query", schema: %{type: "string"}, example: "9090"}
      ]

      expected = [
        %{name: "alias", in: "query", schema: %{type: "string"}, example: "jon"},
        %{name: "id", in: "header", schema: %{type: "string"}, example: "8"},
        %{name: "id", in: "path", required: true, schema: %{type: "string"}, example: 6},
        %{name: "id", in: "query", schema: %{type: "string"}, example: "9090"}
      ]

      assert Formatter.merge_parameter_object_lists(parameters, new_params) == expected
    end

    test "overwrite params with new one" do
      parameters = [
        %{
          name: "id",
          in: "path",
          required: true,
          schema: %{type: "string"},
          example: "invalid-id"
        }
      ]

      new_params = [
        %{name: "id", in: "path", required: true, schema: %{type: "string"}, example: "valid-id"}
      ]

      assert Formatter.merge_parameter_object_lists(parameters, new_params, :overwrite) ==
               new_params
    end
  end

  describe "merge_path_item_objects/3" do
    test "merge objects with diferente responses and choose correct examples" do
      not_found = Samples.not_found_without_req_body()
      bad_request = Samples.bad_request_with_req_body()
      success = Samples.success_with_req_body()

      first_sequence =
        not_found
        |> Formatter.merge_path_item_objects(bad_request, "put")
        |> Formatter.merge_path_item_objects(success, "put")

      second_sequence =
        success
        |> Formatter.merge_path_item_objects(not_found, "put")
        |> Formatter.merge_path_item_objects(bad_request, "put")

      third_sequence =
        bad_request
        |> Formatter.merge_path_item_objects(success, "put")
        |> Formatter.merge_path_item_objects(not_found, "put")

      expected = Samples.all_merged()

      assert first_sequence == expected
      assert second_sequence == expected
      assert third_sequence == expected
    end
  end
end
