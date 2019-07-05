defmodule Xcribe.RequestsExamples do
  defmacro __using__(_opts \\ []) do
    quote do
      alias Xcribe.Request

      @sample_requests [
        %Request{
          action: "index",
          controller: Elixir.Xcribe.UsersController,
          description: "get all users",
          header_params: [{"authorization", "token"}],
          params: %{},
          path: "/users",
          path_params: %{},
          query_params: %{},
          request_body: %{},
          resource: "users",
          resource_group: :api,
          resp_body: "[{\"id\":1,\"name\":\"user 1\"},{\"id\":2,\"name\":\"user 2\"}]",
          resp_headers: [
            {"content-type", "application/json; charset=utf-8"},
            {"cache-control", "max-age=0, private, must-revalidate"}
          ],
          status_code: 200,
          verb: "get"
        },
        %Request{
          action: "create",
          controller: Elixir.Xcribe.UsersController,
          description: "create an user",
          header_params: [
            {"authorization", "token"},
            {"content-type", "multipart/mixed; boundary=plug_conn_test"}
          ],
          params: %{"age" => 5, "name" => "teste"},
          path: "/users",
          path_params: %{},
          query_params: %{},
          request_body: %{"age" => 5, "name" => "teste"},
          resource: "users",
          resource_group: :api,
          resp_body: "{\"age\":5,\"name\":\"teste\"}",
          resp_headers: [
            {"content-type", "application/json; charset=utf-8"},
            {"cache-control", "max-age=0, private, must-revalidate"}
          ],
          status_code: 201,
          verb: "post"
        },
        %Request{
          action: "index",
          controller: Elixir.Xcribe.PostsController,
          description: "get all user posts",
          header_params: [{"authorization", "token"}],
          params: %{"users_id" => "1"},
          path: "/users/{users_id}/posts",
          path_params: %{"users_id" => "1"},
          query_params: %{},
          request_body: %{},
          resource: "users_posts",
          resource_group: :api,
          resp_body: "[{\"id\":1,\"title\":\"user 1\"},{\"id\":2,\"title\":\"user 2\"}]",
          resp_headers: [
            {"content-type", "application/json; charset=utf-8"},
            {"cache-control", "max-age=0, private, must-revalidate"}
          ],
          status_code: 200,
          verb: "get"
        },
        %Request{
          action: "index",
          controller: Elixir.Xcribe.MonitoringController,
          description: "get monitoring info",
          header_params: [{"authorization", "token"}],
          params: %{},
          path: "/monitoring/",
          path_params: %{},
          query_params: %{},
          request_body: %{},
          resource: "monitoring",
          resource_group: :monitoring,
          resp_body: "[{\"status\":\"ok\"}]",
          resp_headers: [
            {"content-type", "application/json; charset=utf-8"}
          ],
          status_code: 200,
          verb: "get"
        }
      ]

      @grouped_sample_requests [
        {"## Group API\n",
         [
           {"## Users Posts [/users/{users_id}/posts/]\n",
            [
              {"### Users Posts index [GET /users/{users_id}/posts/]\n",
               [
                 %Request{
                   action: "index",
                   controller: Elixir.Xcribe.PostsController,
                   description: "get all user posts",
                   header_params: [{"authorization", "token"}],
                   params: %{"users_id" => "1"},
                   path: "/users/{users_id}/posts",
                   path_params: %{"users_id" => "1"},
                   query_params: %{},
                   request_body: %{},
                   resource: "users_posts",
                   resource_group: :api,
                   resp_body: "[{\"id\":1,\"title\":\"user 1\"},{\"id\":2,\"title\":\"user 2\"}]",
                   resp_headers: [
                     {"content-type", "application/json; charset=utf-8"},
                     {"cache-control", "max-age=0, private, must-revalidate"}
                   ],
                   status_code: 200,
                   verb: "get"
                 }
               ]}
            ]},
           {"## Users [/users/]\n",
            [
              {"### Users create [POST /users/]\n",
               [
                 %Request{
                   action: "create",
                   controller: Elixir.Xcribe.UsersController,
                   description: "create an user",
                   header_params: [
                     {"authorization", "token"},
                     {"content-type", "multipart/mixed; boundary=plug_conn_test"}
                   ],
                   params: %{"age" => 5, "name" => "teste"},
                   path: "/users",
                   path_params: %{},
                   query_params: %{},
                   request_body: %{"age" => 5, "name" => "teste"},
                   resource: "users",
                   resource_group: :api,
                   resp_body: "{\"age\":5,\"name\":\"teste\"}",
                   resp_headers: [
                     {"content-type", "application/json; charset=utf-8"},
                     {"cache-control", "max-age=0, private, must-revalidate"}
                   ],
                   status_code: 201,
                   verb: "post"
                 }
               ]},
              {"### Users index [GET /users/]\n",
               [
                 %Request{
                   action: "index",
                   controller: Elixir.Xcribe.UsersController,
                   description: "get all users",
                   header_params: [{"authorization", "token"}],
                   params: %{},
                   path: "/users",
                   path_params: %{},
                   query_params: %{},
                   request_body: %{},
                   resource: "users",
                   resource_group: :api,
                   resp_body: "[{\"id\":1,\"name\":\"user 1\"},{\"id\":2,\"name\":\"user 2\"}]",
                   resp_headers: [
                     {"content-type", "application/json; charset=utf-8"},
                     {"cache-control", "max-age=0, private, must-revalidate"}
                   ],
                   status_code: 200,
                   verb: "get"
                 }
               ]}
            ]}
         ]},
        {"## Group MONITORING\n",
         [
           {"## Monitoring [/monitoring/]\n",
            [
              {"### Monitoring index [GET /monitoring/]\n",
               [
                 %Request{
                   action: "index",
                   controller: Elixir.Xcribe.MonitoringController,
                   description: "get monitoring info",
                   header_params: [{"authorization", "token"}],
                   params: %{},
                   path: "/monitoring/",
                   path_params: %{},
                   query_params: %{},
                   request_body: %{},
                   resource: "monitoring",
                   resource_group: :monitoring,
                   resp_body: "[{\"status\":\"ok\"}]",
                   resp_headers: [
                     {"content-type", "application/json; charset=utf-8"}
                   ],
                   status_code: 200,
                   verb: "get"
                 }
               ]}
            ]}
         ]}
      ]

      @sample_requests_as_string """
      ## Group API
      ## Users Posts [/users/{users_id}/posts/]
      + Parameters

          + users_id: `1` (required, string) - The users_id
      ### Users Posts index [GET /users/{users_id}/posts/]
      + Request get all user posts (text/plain)
          + Headers

                  authorization: token

      + Response 200 (application/json; charset=utf-8)
          + Headers

                  cache-control: max-age=0, private, must-revalidate
          + Body

                  [
                    {
                      "id": 1,
                      "title": "user 1"
                    },
                    {
                      "id": 2,
                      "title": "user 2"
                    }
                  ]
      ## Users [/users/]
      ### Users create [POST /users/]
      + Request create an user (multipart/mixed; boundary=plug_conn_test)
          + Headers

                  authorization: token
          + Body

                  {
                    "age": 5,
                    "name": "teste"
                  }

      + Response 201 (application/json; charset=utf-8)
          + Headers

                  cache-control: max-age=0, private, must-revalidate
          + Body

                  {
                    "age": 5,
                    "name": "teste"
                  }
      ### Users index [GET /users/]
      + Request get all users (text/plain)
          + Headers

                  authorization: token

      + Response 200 (application/json; charset=utf-8)
          + Headers

                  cache-control: max-age=0, private, must-revalidate
          + Body

                  [
                    {
                      "id": 1,
                      "name": "user 1"
                    },
                    {
                      "id": 2,
                      "name": "user 2"
                    }
                  ]
      ## Group MONITORING
      ## Monitoring [/monitoring/]
      ### Monitoring index [GET /monitoring/]
      + Request get monitoring info (text/plain)
          + Headers

                  authorization: token

      + Response 200 (application/json; charset=utf-8)
          + Body

                  [
                    {
                      "status": "ok"
                    }
                  ]
      """
    end
  end
end
