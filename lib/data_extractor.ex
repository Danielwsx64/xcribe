defmodule ApiBluefy.DataExtractor do
  alias ApiBluefy.Structs.ParsedRequest

  def from_conn(conn, name \\ "Request") do
    route = identify_route(conn)

    %ParsedRequest{
      resource_group: resource_group(route),
      resource: route.helper,
      action: route.opts,
      paramters: Map.keys(conn.params),
      headers: conn.req_headers,
      body: conn.params,
      name: name,
      resp_body: conn.resp_body,
      resp_headers: conn.resp_headers,
      status_code: conn.status
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

  defp verb_atom(%{method: verb}), do: verb |> String.downcase() |> String.to_atom()
end
