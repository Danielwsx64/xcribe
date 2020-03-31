defmodule Xcribe.Support.Samples.SwaggerFormater do
  def path_item_object_without_request_body do
    %{
      "put" => %{
        summary: "",
        description: "",
        security: [%{"bearer" => []}],
        parameters: [
          %{
            name: "id",
            in: "path",
            required: true,
            schema: %{type: "string"},
            example: "590eda29-df5f-4244-8159-7bb87e3cc15a"
          }
        ],
        responses: %{
          404 => %{
            description: "",
            content: %{
              "application/json" => %{
                schema: %{properties: %{"message" => %{type: "string"}}, type: "object"}
              }
            },
            headers: %{
              "cache-control" => %{description: "", schema: %{type: "string"}},
              "x-request-id" => %{description: "", schema: %{type: "string"}}
            }
          }
        }
      }
    }
  end

  def path_item_object_with_request_body do
    %{
      "put" => %{
        summary: "",
        description: "",
        security: [%{"bearer" => []}],
        parameters: [
          %{
            example: "3456efae-bc48-44b4-94d0-7670c4772696",
            in: "path",
            name: "id",
            required: true,
            schema: %{type: "string"}
          },
          %{
            name: "include",
            in: "query",
            schema: %{type: "string"},
            example: "user"
          }
        ],
        responses: %{
          200 => %{
            description: "",
            content: %{
              "application/json" => %{schema: %{type: "string", example: "success"}}
            },
            headers: %{
              "cache-control" => %{description: "", schema: %{type: "string"}},
              "x-request-id" => %{description: "", schema: %{type: "string"}}
            }
          }
        },
        requestBody: %{
          description: "",
          content: %{
            "multipart/mixed" => %{
              schema: %{
                type: "object",
                properties: %{
                  "address" => %{
                    properties: %{
                      "city" => %{type: "string"},
                      "complement" => %{type: "string"},
                      "number" => %{format: "int32", type: "number"},
                      "state" => %{type: "string"},
                      "street" => %{type: "string"},
                      "zipcode" => %{type: "string"}
                    },
                    type: "object"
                  },
                  "cnpj" => %{type: "string"},
                  "company_name" => %{type: "string"},
                  "email" => %{type: "string"},
                  "phone" => %{type: "string"},
                  "trading_name" => %{type: "string"}
                }
              }
            }
          }
        }
      }
    }
  end

  def expected_path_objects_merge do
    %{
      "put" => %{
        summary: "",
        description: "",
        security: [%{"bearer" => []}],
        parameters: [
          %{
            name: "include",
            in: "query",
            schema: %{type: "string"},
            example: "user"
          },
          %{
            name: "id",
            in: "path",
            required: true,
            schema: %{type: "string"},
            example: "590eda29-df5f-4244-8159-7bb87e3cc15a"
          }
        ],
        responses: %{
          200 => %{
            description: "",
            content: %{
              "application/json" => %{schema: %{type: "string", example: "success"}}
            },
            headers: %{
              "cache-control" => %{description: "", schema: %{type: "string"}},
              "x-request-id" => %{description: "", schema: %{type: "string"}}
            }
          },
          404 => %{
            description: "",
            content: %{
              "application/json" => %{
                schema: %{properties: %{"message" => %{type: "string"}}, type: "object"}
              }
            },
            headers: %{
              "cache-control" => %{description: "", schema: %{type: "string"}},
              "x-request-id" => %{description: "", schema: %{type: "string"}}
            }
          }
        },
        requestBody: %{
          description: "",
          content: %{
            "multipart/mixed" => %{
              schema: %{
                type: "object",
                properties: %{
                  "address" => %{
                    properties: %{
                      "city" => %{type: "string"},
                      "complement" => %{type: "string"},
                      "number" => %{format: "int32", type: "number"},
                      "state" => %{type: "string"},
                      "street" => %{type: "string"},
                      "zipcode" => %{type: "string"}
                    },
                    type: "object"
                  },
                  "cnpj" => %{type: "string"},
                  "company_name" => %{type: "string"},
                  "email" => %{type: "string"},
                  "phone" => %{type: "string"},
                  "trading_name" => %{type: "string"}
                }
              }
            }
          }
        }
      }
    }
  end
end
