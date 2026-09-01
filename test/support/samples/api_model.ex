defmodule Xcribe.Support.Samples.APIModel do
  @moduledoc false

  alias Xcribe.APIModel.{Body, Example, Operation, Parameter, Response}

  def users_posts_create_operation do
    %Operation{
      verb: "post",
      path: "/users/{users_id}/posts",
      action: "create",
      controller: Xcribe.PostsController,
      resource: "Users Posts",
      descriptions: ["show user post"],
      tags: ["Users Posts"],
      security: [],
      parameters: [
        %Parameter{
          name: "content-type",
          location: :header,
          required: false,
          schema: %{type: "string"},
          examples: ["application/json"]
        },
        %Parameter{
          name: "users_id",
          location: :path,
          required: true,
          schema: %{type: "string"},
          examples: ["1"]
        }
      ],
      request_content: [
        %Body{
          content_type: "application/json",
          schema_name: "createUsersPosts",
          schema: %{
            type: "object",
            properties: %{"title" => %{type: "string", example: "user 1"}}
          },
          examples: [%{"title" => "user 1"}]
        }
      ],
      responses: [
        %Response{
          status: 201,
          headers: [
            %Parameter{
              name: "cache-control",
              location: :header,
              required: false,
              schema: %{type: "string"},
              examples: ["max-age=0, private, must-revalidate"]
            },
            %Parameter{
              name: "content-type",
              location: :header,
              required: false,
              schema: %{type: "string"},
              examples: ["application/json; charset=utf-8"]
            }
          ],
          content: [
            %Body{
              content_type: "application/json",
              schema_name: "UsersPosts",
              schema: %{
                type: "object",
                properties: %{
                  "title" => %{type: "string", example: "user 1"},
                  "users_id" => %{type: "string", example: "1"}
                }
              },
              examples: [%{"title" => "user 1", "users_id" => "1"}]
            }
          ]
        }
      ],
      examples: [
        %Example{
          __meta__: %{},
          description: "show user post",
          status: 201,
          path_params: %{"users_id" => "1"},
          query_params: %{},
          request_content_type: "application/json",
          request_headers: [{"content-type", "application/json"}],
          request_body: %{"title" => "user 1"},
          response_content_type: "application/json",
          response_headers: [
            {"cache-control", "max-age=0, private, must-revalidate"},
            {"content-type", "application/json; charset=utf-8"}
          ],
          response_raw_body: ~s({"title":"user 1","users_id":"1"}),
          response_body: %{"title" => "user 1", "users_id" => "1"},
          response_decode_error: nil
        }
      ]
    }
  end

  def all_requests do
    generator = Xcribe.Support.RequestsGenerator

    [
      generator.users_index(),
      generator.users_show(),
      generator.users_create(),
      generator.users_update(),
      generator.users_delete(),
      generator.users_custom_action(),
      generator.users_posts_index(),
      generator.users_posts_create(),
      generator.users_posts_update(),
      generator.notes_index(),
      generator.namespaced_users_index(),
      generator.no_pipe_users_index()
    ]
  end

  def all_requests_paths_and_verbs do
    [
      {"/namespace_ignored/notes", ["get"]},
      {"/namespace_with_undescore/users", ["get"]},
      {"/nopipe/users", ["get"]},
      {"/users", ["get", "post"]},
      {"/users/{id}", ["delete", "get", "put"]},
      {"/users/{users_id}/cancel", ["post"]},
      {"/users/{users_id}/posts", ["get", "post"]},
      {"/users/{users_id}/posts/{id}", ["patch"]}
    ]
  end

  def all_requests_schema_names do
    [
      "NamespaceIgnoredNotes",
      "NamespaceWithUndescoreUsers",
      "NopipeUsers",
      "Users",
      "UsersPosts",
      "createUsers",
      "createUsersPosts",
      "updateUsers",
      "updateUsersPosts"
    ]
  end
end
