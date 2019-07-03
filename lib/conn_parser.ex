defmodule Xcribe.ConnParser do
  alias Xcribe.Request

  def execute(conn, _name \\ "Request") do
    route = identify_route(conn)

    %Request{
      action: Atom.to_string(route.opts),
      header_params: conn.req_headers,
      controller: conn |> controller_module() |> Atom.to_string(),
      params: conn.params,
      path: format_path(route.path, Map.keys(conn.path_params)),
      path_params: conn.path_params,
      query_params: conn.query_params,
      request_body: conn.body_params,
      resource: resource_name(route),
      resource_group: resource_group(route),
      resp_body: conn.resp_body,
      resp_headers: conn.resp_headers,
      status_code: conn.status,
      verb: Atom.to_string(route.verb)
    }
  end

  defp identify_route(conn) do
    conn
    |> router_module()
    |> apply(:__routes__, [])
    |> enum_find(conn)
  end

  defp enum_find(routes, conn) do
    routes
    |> Enum.find(fn route -> has_eql_values?(route, conn) end)
  end

  defp has_eql_values?(route, conn) do
    route.plug == controller_module(conn) and route.opts == action_atom(conn) and
      route.verb == verb_atom(conn) and match_path?(route, conn)
  end

  defp match_path?(%{path: route_path}, %{request_path: conn_path}),
    do: Regex.match?(regex_to(route_path), conn_path)

  defp regex_to(path), do: ~r/#{replace_params(path)}/

  defp replace_params(path), do: String.replace(path, ~r/\:\w+/, ".*")

  defp router_module(%{private: %{phoenix_router: router}}), do: router

  defp controller_module(%{private: %{phoenix_controller: controller}}), do: controller

  defp action_atom(%{private: %{phoenix_action: action}}), do: action

  defp resource_group(%{pipe_through: [head | _rest]}), do: head

  defp resource_name(%{helper: nil, plug: controller}),
    do: resource_name_by_controller(controller)

  defp resource_name(%{helper: name}), do: name

  defp resource_name_by_controller(controller) do
    ~r/\.(\w+)Controller$/
    |> Regex.run(to_string(controller))
    |> List.last()
    |> String.downcase()
  end

  defp verb_atom(%{method: verb}), do: verb |> String.downcase() |> String.to_atom()

  defp format_path(path, params), do: Enum.reduce(params, path, &transform_param/2)

  defp transform_param(param, path), do: String.replace(path, ":#{param}", "{#{param}}")
end
