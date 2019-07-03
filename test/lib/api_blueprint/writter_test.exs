defmodule Xcribe.ApiBlueprint.WritterTest do
  use ExUnit.Case, async: true

  alias Xcribe.ApiBlueprint.Writter
  alias Xcribe.Structs.ParsedRequest

  @sample_requests [
    %ParsedRequest{
      action: "index",
      controller: "Elixir.Xcribe.UsersController",
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
    %ParsedRequest{
      action: "create",
      controller: "Elixir.Xcribe.UsersController",
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
    %ParsedRequest{
      action: "index",
      controller: "Elixir.Xcribe.PostsController",
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
    %ParsedRequest{
      action: "index",
      controller: "Elixir.Xcribe.MonitoringController",
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
    api: [
      {"users",
       [
         {"create",
          [
            %Xcribe.Structs.ParsedRequest{
              action: "create",
              controller: "Elixir.Xcribe.UsersController",
              description: nil,
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
         {"index",
          [
            %Xcribe.Structs.ParsedRequest{
              action: "index",
              controller: "Elixir.Xcribe.UsersController",
              description: nil,
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
       ]},
      {"users_posts",
       [
         {"index",
          [
            %Xcribe.Structs.ParsedRequest{
              action: "index",
              controller: "Elixir.Xcribe.PostsController",
              description: nil,
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
       ]}
    ],
    monitoring: [
      {"monitoring",
       [
         {"index",
          [
            %Xcribe.Structs.ParsedRequest{
              action: "index",
              controller: "Elixir.Xcribe.MonitoringController",
              description: nil,
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
    ]
  ]

  describe "group_requests/1" do
    test "group requests" do
      assert Writter.group_requests(@sample_requests) == @grouped_sample_requests
    end
  end

  describe "grouped_requests_to_string/1" do
    test "parse routes to string" do
      assert Writter.grouped_requests_to_string(@grouped_sample_requests) == ""
    end
  end
end
