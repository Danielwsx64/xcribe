defmodule Xcribe.Swagger.FormatterTest do
  use ExUnit.Case, async: true

  alias Xcribe.Swagger.Formatter
  alias Xcribe.Request

  describe "request_parameters/1" do
    test "with some parameters" do
      request = %Request{
        path_params: %{"id" => 1, "post_title" => "title"},
        query_params: %{"name" => "test"},
        header_params: [{"x-client-id", "123456678"}],
        controller: Elixir.Xcribe.PostsController,
        action: "show"
      }

      expected = [
        %{
          "name" => "x-client-id",
          "in" => "header",
          "description" => "",
          "required" => false,
          "schema" => %{"type" => "string"}
        },
        %{
          "name" => "name",
          "in" => "query",
          "description" => "",
          "required" => false,
          "schema" => %{"type" => "string"}
        },
        %{
          "name" => "post_title",
          "in" => "path",
          "description" => "",
          "required" => true,
          "schema" => %{"type" => "string"}
        },
        %{
          "name" => "id",
          "in" => "path",
          "description" => "",
          "required" => true,
          "schema" => %{"type" => "integer"}
        }
      ]

      assert Formatter.request_parameters(request) == expected
    end

    test "without any parameters" do
      request = %Request{
        path_params: %{},
        query_params: %{},
        header_params: []
      }

      assert Formatter.request_parameters(request) == []
    end
  end

  describe "request_body/1" do
    test "when body is a map" do
      request = %{
        request_body: %{
          "user_id" => 1,
          "email" => "user@email.com"
        },
        controller: Elixir.Xcribe.UsersController,
        resp_headers: [
          {"content-type", "application/json; charset=utf-8"}
        ]
      }

      expected = %{
        "required" => true,
        "content" => %{
          "application/json" => %{
            "schema" => %{
              "type" => "object",
              "properties" => %{
                "user_id" => %{
                  "type" => "integer",
                  "description" => ""
                },
                "email" => %{
                  "type" => "string",
                  "description" => ""
                }
              }
            }
          }
        }
      }

      assert Formatter.request_body(request) == expected
    end
  end

  describe "format_responses/1" do
    test "when response body is a list" do
      request = %{
        status_code: 200,
        description: "Sucess",
        resp_headers: [
          {"content-type", "application/json; charset=utf-8"},
          {"cache-control", "max-age=0, private, must-revalidate"}
        ],
        resp_body: "[{\"id\":1,\"name\":\"user 1\"},{\"id\":2,\"name\":\"user 2\"}]"
      }

      expected = %{
        200 => %{
          "description" => "Sucess",
          "headers" => %{
            "content-type" => %{
              "schema" => %{
                "type" => "string"
              }
            },
            "cache-control" => %{
              "schema" => %{
                "type" => "string"
              }
            }
          },
          "content" => %{
            "application/json" => %{
              "schema" => %{
                "type" => "array",
                "items" => %{
                  "type" => "object",
                  "properties" => %{
                    "id" => %{
                      "type" => "integer",
                      "description" => ""
                    },
                    "name" => %{
                      "type" => "string",
                      "description" => ""
                    }
                  }
                }
              }
            }
          }
        }
      }

      assert Formatter.format_responses(request) == expected
    end

    test "when response body is a map" do
      request = %{
        status_code: 200,
        description: "Sucess",
        resp_headers: [
          {"content-type", "application/json; charset=utf-8"},
          {"cache-control", "max-age=0, private, must-revalidate"}
        ],
        resp_body: "{\"id\":1,\"name\":\"user 1\"}"
      }

      expected = %{
        200 => %{
          "description" => "Sucess",
          "headers" => %{
            "content-type" => %{
              "schema" => %{
                "type" => "string"
              }
            },
            "cache-control" => %{
              "schema" => %{
                "type" => "string"
              }
            }
          },
          "content" => %{
            "application/json" => %{
              "schema" => %{
                "type" => "object",
                "properties" => %{
                  "id" => %{
                    "type" => "integer",
                    "description" => ""
                  },
                  "name" => %{
                    "type" => "string",
                    "description" => ""
                  }
                }
              }
            }
          }
        }
      }

      assert Formatter.format_responses(request) == expected
    end

    test "when response body is empty" do
      request = %{
        status_code: 204,
        description: "Sucess",
        resp_headers: [
          {"cache-control", "max-age=0, private, must-revalidate"}
        ],
        resp_body: ""
      }

      expected = %{
        204 => %{
          "description" => "Sucess",
          "headers" => %{
            "cache-control" => %{
              "schema" => %{
                "type" => "string"
              }
            }
          },
          "content" => %{
            "text/plain" => %{
              "schema" => %{
                "type" => "string",
                "example" => ""
              }
            }
          }
        }
      }

      assert Formatter.format_responses(request) == expected
    end

    test "when response body is a XML response" do
      request = %{
        status_code: 200,
        description: "Sucess",
        resp_headers: [
          {"content-type", "application/xml; charset=utf-8"},
          {"cache-control", "max-age=0, private, must-revalidate"}
        ],
        resp_body: "<user><id>1</id><name>user 1</name></user>"
      }

      expected = %{
        200 => %{
          "description" => "Sucess",
          "headers" => %{
            "content-type" => %{
              "schema" => %{
                "type" => "string"
              }
            },
            "cache-control" => %{
              "schema" => %{
                "type" => "string"
              }
            }
          },
          "content" => %{
            "application/xml" => %{
              "schema" => %{
                "type" => "string",
                "example" => "<user><id>1</id><name>user 1</name></user>"
              }
            }
          }
        }
      }

      assert Formatter.format_responses(request) == expected
    end
  end
end
