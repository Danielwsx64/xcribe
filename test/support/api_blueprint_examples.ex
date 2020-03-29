defmodule Xcribe.ApiBlueprintExamples do
  defmacro __using__(_opts \\ []) do
    quote do
      alias Xcribe.Request

      @grouped_sample_requests [
        {"## Group API\n",
         [
           {"## Users Posts [/users/{usersId}/posts/]\n",
            [
              {"### Users Posts show [GET /users/{usersId}/posts/{id}/]\n",
               [
                 %Request{
                   action: "show",
                   controller: Elixir.Xcribe.PostsController,
                   description: "get all user posts",
                   header_params: [{"authorization", "token"}],
                   params: %{"users_id" => "1"},
                   path: "/users/{users_id}/posts/{id}",
                   path_params: %{"users_id" => "1", "id" => "2"},
                   query_params: %{},
                   request_body: %{},
                   resource: "users_posts",
                   resource_group: :api,
                   resp_body: "{\"id\":1,\"title\":\"user 1\"}",
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
                     {"content-type", "application/json; boundary=plug_conn_test"}
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

      @sample_requests_as_string File.read!("test/support/api_blueprint_example.apib")
    end
  end
end
