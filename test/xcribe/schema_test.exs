defmodule Xcribe.SchemaTest do
  use ExUnit.Case, async: true

  alias Xcribe.Schema

  describe "merge/2" do
    test "when base has no schemas" do
      base_schemas = %{}

      new_schema = %{
        "putUsers" => %{
          type: "object",
          properties: %{"file" => %{format: "binary", type: "string"}}
        }
      }

      assert Schema.merge(base_schemas, new_schema) == new_schema
    end

    test "when new has no schemas" do
      base_schemas = %{
        "putUsers" => %{
          type: "object",
          properties: %{"file" => %{format: "binary", type: "string"}}
        }
      }

      new_schema = %{}

      assert Schema.merge(base_schemas, new_schema) == base_schemas
    end

    test "when new has different schemas" do
      base_schemas = %{
        "putUsers" => %{
          type: "object",
          properties: %{"file" => %{format: "binary", type: "string"}}
        }
      }

      new_schema = %{
        "Users" => %{
          type: "object",
          properties: %{"name" => %{example: "user 1", type: "string"}}
        }
      }

      assert Schema.merge(base_schemas, new_schema) == Map.merge(base_schemas, new_schema)
    end

    test "when the new schemas are alread in the base" do
      base_schemas = %{
        "Users" => %{
          properties: %{"name" => %{example: "user 1", type: "string"}},
          type: "object"
        },
        "putUsers" => %{
          type: "object",
          properties: %{"file" => %{format: "binary", type: "string"}}
        }
      }

      new_schema = %{
        "putUsers" => %{
          type: "object",
          properties: %{"file" => %{format: "binary", type: "string"}}
        }
      }

      assert Schema.merge(base_schemas, new_schema) == base_schemas
    end

    test "when new schemas has new attributes" do
      base_schemas = %{
        "putUsers" => %{
          type: "object",
          properties: %{"file" => %{format: "binary", type: "string"}}
        }
      }

      new_schema = %{
        "putUsers" => %{
          type: "object",
          properties: %{"user_id" => %{example: "123", type: "string"}}
        }
      }

      expected = %{
        "putUsers" => %{
          type: "object",
          properties: %{
            "file" => %{format: "binary", type: "string"},
            "user_id" => %{example: "123", type: "string"}
          }
        }
      }

      assert Schema.merge(base_schemas, new_schema) == expected
    end

    test "when new schemas has new examples" do
      base_schemas = %{
        "putUsers" => %{
          type: "object",
          properties: %{"file" => %{format: "binary", type: "string"}}
        }
      }

      new_schema = %{
        "putUsers" => %{
          type: "object",
          properties: %{"file" => %{format: "binary", type: "string", example: "new example"}}
        }
      }

      assert Schema.merge(base_schemas, new_schema) == new_schema
    end

    test "when new schemas has different type keep the new one" do
      base_schemas = %{
        "putUsers" => %{
          type: "object",
          properties: %{"file" => %{format: "binary", type: "string"}}
        }
      }

      new_schema = %{
        "putUsers" => %{
          type: "object",
          properties: %{"file" => %{format: "int32", type: "number", example: 12}}
        }
      }

      assert Schema.merge(base_schemas, new_schema) == new_schema
    end

    test "handle nested objects" do
      base_schemas = %{
        "putUsers" => %{
          type: "object",
          properties: %{
            "file" => %{
              type: "object",
              properties: %{"name" => %{format: "binary", type: "string"}}
            }
          }
        }
      }

      new_schema = %{
        "putUsers" => %{
          type: "object",
          properties: %{
            "file" => %{
              type: "object",
              properties: %{"name" => %{format: "binary", type: "string", example: "daniel"}}
            }
          }
        }
      }

      assert Schema.merge(base_schemas, new_schema) == new_schema
    end

    test "handle array schemas" do
      base_schemas = %{
        "putUsers" => %{
          type: "array",
          items: %{
            type: "object",
            properties: %{
              id: %{example: 1, format: "int32", type: "number"}
            }
          }
        }
      }

      new_schema = %{
        "putUsers" => %{
          type: "array",
          items: %{
            type: "object",
            properties: %{
              name: %{example: "user 1", type: "string"}
            }
          }
        }
      }

      expected = %{
        "putUsers" => %{
          type: "array",
          items: %{
            type: "object",
            properties: %{
              id: %{example: 1, format: "int32", type: "number"},
              name: %{example: "user 1", type: "string"}
            }
          }
        }
      }

      assert Schema.merge(base_schemas, new_schema) == expected
    end
  end

  describe "merge_schema/2" do
    test "merge two object schemas without properties" do
      base = %{type: "object", description: "A user"}
      new = %{type: "object", title: "Users"}

      # Only `properties` is merged for an object; the base keeps every other key it declared.
      assert Schema.merge_schema(base, new) == %{
               type: "object",
               description: "A user",
               properties: %{}
             }
    end

    test "keep a hand written description while taking generated properties" do
      base = %{type: "object", description: "Every user in the account"}
      new = %{type: "object", properties: %{"id" => %{type: "number", example: 1}}}

      assert Schema.merge_schema(base, new) == %{
               type: "object",
               description: "Every user in the account",
               properties: %{"id" => %{type: "number", example: 1}}
             }
    end

    test "merge two array schemas without items" do
      assert Schema.merge_schema(%{type: "array"}, %{type: "array"}) == %{
               type: "array",
               items: %{}
             }
    end

    test "a schema of a different type replaces the base" do
      assert Schema.merge_schema(%{type: "object"}, %{type: "string"}) == %{type: "string"}
    end
  end
end
