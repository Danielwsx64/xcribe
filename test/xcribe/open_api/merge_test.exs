defmodule Xcribe.OpenAPI.MergeTest do
  use ExUnit.Case, async: true

  alias Xcribe.OpenAPI.Merge

  describe "overlay_paths/2" do
    test "specification values win over generated ones" do
      generated = %{
        "/users" => %{
          "get" => %{description: "show users", tags: ["Users"], responses: %{}}
        }
      }

      specified = %{"/users" => %{"get" => %{description: "List every user"}}}

      assert Merge.overlay_paths(generated, specified) == %{
               "/users" => %{
                 "get" => %{description: "List every user", tags: ["Users"], responses: %{}}
               }
             }
    end

    test "add a path the tests never documented" do
      specified = %{"/health" => %{"get" => %{description: "Liveness probe"}}}

      assert Merge.overlay_paths(%{}, specified) == specified
    end

    test "add a verb to an already documented path" do
      generated = %{"/users" => %{"get" => %{description: "show users"}}}
      specified = %{"/users" => %{"delete" => %{description: "Remove a user"}}}

      assert Merge.overlay_paths(generated, specified) == %{
               "/users" => %{
                 "get" => %{description: "show users"},
                 "delete" => %{description: "Remove a user"}
               }
             }
    end

    test "overlay nested objects without discarding sibling keys" do
      generated = %{
        "/users" => %{
          "get" => %{
            responses: %{
              "200" => %{description: "", headers: %{"etag" => %{}}}
            }
          }
        }
      }

      specified = %{
        "/users" => %{"get" => %{responses: %{"200" => %{description: "A user list"}}}}
      }

      assert Merge.overlay_paths(generated, specified) == %{
               "/users" => %{
                 "get" => %{
                   responses: %{
                     "200" => %{description: "A user list", headers: %{"etag" => %{}}}
                   }
                 }
               }
             }
    end

    test "keep generated paths untouched when the specification has none" do
      generated = %{"/users" => %{"get" => %{description: "show users"}}}

      assert Merge.overlay_paths(generated, %{}) == generated
    end
  end
end
