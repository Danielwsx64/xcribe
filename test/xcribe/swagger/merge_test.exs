defmodule Xcribe.Swagger.MergeTest do
  use ExUnit.Case, async: true

  alias Xcribe.Swagger.Merge

  describe "paths/2" do
    test "when base has no paths" do
      base_paths = %{}

      new_path = %{
        "/users" => %{
          "get" => %{
            parameters: [],
            security: [%{"api_key" => []}],
            tags: ["Users"],
            responses: %{}
          }
        }
      }

      assert Merge.paths(base_paths, new_path) == new_path
    end

    test "when new has no paths" do
      base_paths = %{
        "/users" => %{
          "get" => %{
            parameters: [],
            security: [%{"api_key" => []}],
            tags: ["Users"],
            responses: %{}
          }
        }
      }

      new_path = %{}

      assert Merge.paths(base_paths, new_path) == base_paths
    end

    test "when new has a different path" do
      base_paths = %{
        "/users" => %{
          "get" => %{
            parameters: [],
            security: [%{"api_key" => []}],
            tags: ["Users"],
            responses: %{}
          }
        }
      }

      new_path = %{
        "/posts" => %{
          "get" => %{
            parameters: [],
            security: [%{"api_key" => []}],
            tags: ["Posts"],
            responses: %{}
          }
        }
      }

      assert Merge.paths(base_paths, new_path) == Map.merge(base_paths, new_path)
    end

    test "when new has a different verb" do
      base_paths = %{
        "/users" => %{
          "get" => %{
            parameters: [],
            security: [%{"api_key" => []}],
            tags: ["Users"],
            responses: %{}
          }
        }
      }

      new_path = %{
        "/users" => %{
          "post" => %{
            parameters: [],
            security: [%{"api_key" => []}],
            tags: ["Users"],
            responses: %{}
          }
        }
      }

      assert Merge.paths(base_paths, new_path) ==
               put_in(base_paths, ["/users", "post"], new_path["/users"]["post"])
    end

    test "when base and new are the same" do
      base_paths = %{
        "/users" => %{
          "get" => %{
            parameters: [],
            security: [%{"api_key" => []}],
            tags: ["Users"],
            responses: %{}
          }
        }
      }

      new_path = %{
        "/users" => %{
          "get" => %{
            parameters: [],
            security: [%{"api_key" => []}],
            tags: ["Users"],
            responses: %{}
          }
        }
      }

      assert Merge.paths(base_paths, new_path) == new_path
    end

    test "when base has not requestBody but new has" do
      base_paths = %{
        "/users" => %{
          "post" => %{
            parameters: [],
            security: [],
            tags: ["Users"],
            responses: %{}
          }
        }
      }

      new_path = %{
        "/users" => %{
          "post" => %{
            parameters: [],
            security: [],
            tags: ["Users"],
            responses: %{},
            requestBody: %{
              content: %{
                "application/json" => %{schema: %{"$ref" => "#/components/schemas/postUsers"}}
              }
            }
          }
        }
      }

      assert Merge.paths(base_paths, new_path) == new_path
    end

    test "when base has requestBody but new has not" do
      base_paths = %{
        "/users" => %{
          "post" => %{
            parameters: [],
            security: [],
            tags: ["Users"],
            responses: %{},
            requestBody: %{
              content: %{
                "application/json" => %{schema: %{"$ref" => "#/components/schemas/postUsers"}}
              }
            }
          }
        }
      }

      new_path = %{
        "/users" => %{
          "post" => %{
            parameters: [],
            security: [],
            tags: ["Users"],
            responses: %{}
          }
        }
      }

      assert Merge.paths(base_paths, new_path) == base_paths
    end

    test "when requestBody has diff schemas" do
      base_paths = %{
        "/users" => %{
          "post" => %{
            parameters: [],
            security: [],
            tags: ["Users"],
            responses: %{},
            requestBody: %{
              content: %{
                "application/json" => %{schema: %{"$ref" => "#/components/schemas/postUsers"}}
              }
            }
          }
        }
      }

      new_path = %{
        "/users" => %{
          "post" => %{
            parameters: [],
            security: [],
            tags: ["Users"],
            responses: %{},
            requestBody: %{
              content: %{
                "application/json" => %{
                  schema: %{"$ref" => "#/components/schemas/otherPostUsers"}
                }
              }
            }
          }
        }
      }

      expected = %{
        "/users" => %{
          "post" => %{
            parameters: [],
            requestBody: %{
              content: %{
                "application/json" => %{
                  schema: %{
                    oneOf: [
                      %{"$ref" => "#/components/schemas/postUsers"},
                      %{"$ref" => "#/components/schemas/otherPostUsers"}
                    ]
                  }
                }
              }
            },
            responses: %{},
            security: [],
            tags: ["Users"]
          }
        }
      }

      assert Merge.paths(base_paths, new_path) == expected
    end
  end

  describe "parameters/2" do
    test "when base has no parameters" do
      base_parameters = []

      new_parameters = [
        %{name: "id", in: "path", required: true, schema: %{type: "string"}, example: 6}
      ]

      assert Merge.parameters(base_parameters, new_parameters) == new_parameters
    end

    test "when new has no parameters" do
      base_parameters = [
        %{name: "id", in: "path", required: true, schema: %{type: "string"}, example: 6}
      ]

      new_parameters = []

      assert Merge.parameters(base_parameters, new_parameters) == base_parameters
    end

    test "when base and new are equals" do
      base_parameters = [
        %{name: "id", in: "path", required: true, schema: %{type: "string"}, example: 6}
      ]

      new_parameters = [
        %{name: "id", in: "path", required: true, schema: %{type: "string"}, example: 6}
      ]

      assert Merge.parameters(base_parameters, new_parameters) == base_parameters
    end

    test "when new has new attributes" do
      base_parameters = [
        %{name: "id", in: "path", required: true, schema: %{type: "string"}, example: 6}
      ]

      new_parameters = [
        %{name: "alias", in: "query", schema: %{type: "string"}, example: "jon"}
      ]

      expected = [
        %{name: "alias", in: "query", schema: %{type: "string"}, example: "jon"},
        %{name: "id", in: "path", required: true, schema: %{type: "string"}, example: 6}
      ]

      assert Merge.parameters(base_parameters, new_parameters) == expected
    end

    test "when has a object parameters" do
      base_parameters = [
        %{
          name: "fields",
          example: %{"articles" => "title,body", "people" => "name"},
          in: "query",
          schema: %{
            properties: %{"articles" => %{type: "string"}, "people" => %{type: "string"}},
            type: "object"
          }
        },
        %{name: "include", example: "author", in: "query", schema: %{type: "string"}}
      ]

      new_parameters = [
        %{
          name: "fields",
          example: %{"articles" => "title,body", "people" => "name", "comments" => "nice one"},
          in: "query",
          schema: %{
            properties: %{
              "articles" => %{type: "string"},
              "people" => %{type: "string"},
              "comments" => %{type: "string"}
            },
            type: "object"
          }
        }
      ]

      expected = [
        %{
          name: "fields",
          example: %{"articles" => "title,body", "people" => "name", "comments" => "nice one"},
          in: "query",
          schema: %{
            properties: %{
              "articles" => %{type: "string"},
              "people" => %{type: "string"},
              "comments" => %{type: "string"}
            },
            type: "object"
          }
        },
        %{name: "include", example: "author", in: "query", schema: %{type: "string"}}
      ]

      assert Merge.parameters(base_parameters, new_parameters) == expected
    end
  end

  describe "responses/2" do
    test "when base has no responses" do
      base_responses = %{}

      new_responses = %{
        200 => %{
          headers: %{"cache-control" => %{schema: %{type: "string"}}},
          content: %{
            "application/json" => %{
              schema: %{"$ref" => "#/components/schemas/Users"}
            }
          }
        }
      }

      assert Merge.responses(base_responses, new_responses) == new_responses
    end

    test "when new has no responses" do
      base_responses = %{
        200 => %{
          headers: %{"cache-control" => %{schema: %{type: "string"}}},
          content: %{
            "application/json" => %{
              schema: %{"$ref" => "#/components/schemas/Users"}
            }
          }
        }
      }

      new_responses = %{}

      assert Merge.responses(base_responses, new_responses) == base_responses
    end

    test "when base and new are equal" do
      base_responses = %{
        200 => %{
          headers: %{"cache-control" => %{schema: %{type: "string"}}},
          content: %{
            "application/json" => %{
              schema: %{"$ref" => "#/components/schemas/Users"}
            }
          }
        }
      }

      new_responses = %{
        200 => %{
          headers: %{"cache-control" => %{schema: %{type: "string"}}},
          content: %{
            "application/json" => %{
              schema: %{"$ref" => "#/components/schemas/Users"}
            }
          }
        }
      }

      assert Merge.responses(base_responses, new_responses) == base_responses
    end

    test "when has diff status code" do
      base_responses = %{
        200 => %{
          headers: %{"cache-control" => %{schema: %{type: "string"}}},
          content: %{
            "application/json" => %{
              schema: %{"$ref" => "#/components/schemas/Users"}
            }
          }
        }
      }

      new_responses = %{
        422 => %{
          headers: %{"cache-control" => %{schema: %{type: "string"}}},
          content: %{
            "application/json" => %{
              schema: %{"$ref" => "#/components/schemas/errorUsers"}
            }
          }
        }
      }

      assert Merge.responses(base_responses, new_responses) ==
               Map.merge(base_responses, new_responses)
    end

    test "when has diff content type" do
      base_responses = %{
        200 => %{
          headers: %{"cache-control" => %{schema: %{type: "string"}}},
          content: %{
            "application/json" => %{
              schema: %{"$ref" => "#/components/schemas/Users"}
            }
          }
        }
      }

      new_responses = %{
        200 => %{
          headers: %{"cache-control" => %{schema: %{type: "string"}}},
          content: %{
            "text/plain" => %{
              schema: %{"$ref" => "#/components/schemas/textUsers"}
            }
          }
        }
      }

      expected = %{
        200 => %{
          headers: %{"cache-control" => %{schema: %{type: "string"}}},
          content: %{
            "application/json" => %{
              schema: %{"$ref" => "#/components/schemas/Users"}
            },
            "text/plain" => %{
              schema: %{"$ref" => "#/components/schemas/textUsers"}
            }
          }
        }
      }

      assert Merge.responses(base_responses, new_responses) == expected
    end

    test "when point to diff schemas" do
      base_responses = %{
        200 => %{
          headers: %{"cache-control" => %{schema: %{type: "string"}}},
          content: %{
            "application/json" => %{
              schema: %{"$ref" => "#/components/schemas/Users"}
            }
          }
        }
      }

      new_responses = %{
        200 => %{
          headers: %{"cache-control" => %{schema: %{type: "string"}}},
          content: %{
            "application/json" => %{
              schema: %{"$ref" => "#/components/schemas/otherUsers"}
            }
          }
        }
      }

      expected = %{
        200 => %{
          headers: %{"cache-control" => %{schema: %{type: "string"}}},
          content: %{
            "application/json" => %{
              schema: %{
                oneOf: [
                  %{"$ref" => "#/components/schemas/Users"},
                  %{"$ref" => "#/components/schemas/otherUsers"}
                ]
              }
            }
          }
        }
      }

      assert Merge.responses(base_responses, new_responses) == expected
    end

    test "when base has oneOf schemas" do
      base_responses = %{
        200 => %{
          headers: %{"cache-control" => %{schema: %{type: "string"}}},
          content: %{
            "application/json" => %{
              schema: %{
                oneOf: [
                  %{"$ref" => "#/components/schemas/otherUsers"},
                  %{"$ref" => "#/components/schemas/Users"}
                ]
              }
            }
          }
        }
      }

      new_responses_already_added = %{
        200 => %{
          headers: %{"cache-control" => %{schema: %{type: "string"}}},
          content: %{
            "application/json" => %{
              schema: %{"$ref" => "#/components/schemas/otherUsers"}
            }
          }
        }
      }

      new_responses_with_new_schema = %{
        200 => %{
          headers: %{"cache-control" => %{schema: %{type: "string"}}},
          content: %{
            "application/json" => %{
              schema: %{"$ref" => "#/components/schemas/otherCoolUsers"}
            }
          }
        }
      }

      expected = %{
        200 => %{
          content: %{
            "application/json" => %{
              schema: %{
                oneOf: [
                  %{"$ref" => "#/components/schemas/otherCoolUsers"},
                  %{"$ref" => "#/components/schemas/otherUsers"},
                  %{"$ref" => "#/components/schemas/Users"}
                ]
              }
            }
          },
          headers: %{"cache-control" => %{schema: %{type: "string"}}}
        }
      }

      assert Merge.responses(base_responses, new_responses_already_added) == base_responses
      assert Merge.responses(base_responses, new_responses_with_new_schema) == expected
    end

    test "when has diff headers" do
      base_responses = %{
        200 => %{
          headers: %{"cache-control" => %{schema: %{type: "string"}}},
          content: %{
            "application/json" => %{
              schema: %{"$ref" => "#/components/schemas/Users"}
            }
          }
        }
      }

      new_responses = %{
        200 => %{
          headers: %{"x-request-id" => %{schema: %{type: "string"}}},
          content: %{
            "application/json" => %{
              schema: %{"$ref" => "#/components/schemas/Users"}
            }
          }
        }
      }

      expected = %{
        200 => %{
          content: %{"application/json" => %{schema: %{"$ref" => "#/components/schemas/Users"}}},
          headers: %{
            "cache-control" => %{schema: %{type: "string"}},
            "x-request-id" => %{schema: %{type: "string"}}
          }
        }
      }

      assert Merge.responses(base_responses, new_responses) == expected
    end

    test "when has no contetn" do
      base_responses = %{
        204 => %{
          description: "",
          headers: %{"x-request-id" => %{schema: %{type: "string"}}}
        }
      }

      new_responses = %{
        204 => %{
          description: "",
          headers: %{
            "access-control-allow-credentials" => %{schema: %{type: "string"}},
            "access-control-allow-origin" => %{schema: %{type: "string"}},
            "access-control-expose-headers" => %{schema: %{type: "string"}}
          }
        }
      }

      expected = %{
        204 => %{
          description: "",
          headers: %{
            "access-control-allow-credentials" => %{schema: %{type: "string"}},
            "access-control-allow-origin" => %{schema: %{type: "string"}},
            "access-control-expose-headers" => %{schema: %{type: "string"}},
            "x-request-id" => %{schema: %{type: "string"}}
          }
        }
      }

      assert Merge.responses(base_responses, new_responses) == expected
    end
  end
end
